
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/network_checker.dart';
import '../model/profile_load_source.dart';
import '../model/profile_model.dart';
import 'profile_local_datasource.dart';
import 'profile_lru_cache.dart';
import 'profile_photo_compressor.dart';
import 'profile_photo_storage.dart';
import 'profile_remote_datasource.dart';
import 'profile_sync_worker.dart';

/// Repository that manages the user's profile and the profiles of friends.
/// It decides if data comes from memory, the device or Firestore.
/// It is shared by the whole app so the memory cache outlives each screen.
class ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;
  final ProfileLocalDatasource _localDatasource;
  final ProfilePhotoStorage _photoStorage;
  final ProfilePhotoCompressor _photoCompressor;
  final ProfileLruCache _friendsCache;

  // Uses the provided dependencies or creates the default ones
  ProfileRepository({
    ProfileRemoteDatasource? remoteDatasource,
    ProfileLocalDatasource? localDatasource,
    ProfilePhotoStorage? photoStorage,
    ProfilePhotoCompressor? photoCompressor,
    ProfileLruCache? friendsCache,
  })  : _remoteDatasource = remoteDatasource ?? ProfileRemoteDatasource(),
        _localDatasource = localDatasource ?? ProfileLocalDatasource(),
        _photoStorage = photoStorage ?? ProfilePhotoStorage(),
        _photoCompressor = photoCompressor ?? ProfilePhotoCompressor(),
        _friendsCache = friendsCache ?? ProfileLruCache();

  // Checks if the device has a network connection before calling Firebase
  Future<bool> isOnline() => NetworkChecker.isOnline();

  // Emits true when the connection comes back and false when it is lost
  Stream<bool> watchConnection() => Connectivity()
      .onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none))
      .distinct();

  // Lets the screen know when the sync worker finished
  void listenForSyncFinished(void Function() onFinished) =>
      ProfileSyncWorker.listenForUiRefresh(onFinished);

  void stopListeningForSyncFinished() =>
      ProfileSyncWorker.stopListeningForUiRefresh();

  // Gets a friend's profile from memory if it was seen in the last minutes
  ProfileModel? getCachedFriendProfile(String uid) => _friendsCache.get(uid);

  // Gets the last saved own profile with the changes not sent yet,
  // or null if it was never saved
  Future<ProfileModel?> getStoredOwnProfile(String uid) async {
    final profile = await _localDatasource.getOwnProfile(uid);
    if (profile == null) return null;
    return _withPendingChanges(profile);
  }

  // Gets the last saved profile of a friend and when it was downloaded
  Future<({ProfileModel profile, DateTime updatedAt})?> getStoredFriendProfile(
          String uid) =>
      _localDatasource.getFriendProfile(uid);

  // Gets the photo saved on the device, or null if there is none
  Future<Uint8List?> getStoredPhoto(String uid) =>
      _photoStorage.readPhoto(uid);

  // Indicates if the name or photo changed offline were not sent yet
  Future<bool> hasPendingChanges(String uid) async =>
      await _localDatasource.getPendingName(uid) != null ||
      await _localDatasource.hasPendingPhoto(uid);

  // Downloads the own profile and saves it on the device
  Future<ProfileModel> refreshOwnProfile(String uid) async {
    final profile = await _remoteDatasource.fetchProfile(uid);
    await _localDatasource.saveOwnProfile(profile);
    // Firestore does not have the pending changes yet, so keep showing them
    return _withPendingChanges(profile);
  }

  // Emits a friend's profile every time it changes and saves each version
  Stream<ProfileModel> watchFriendProfile(String uid) =>
      _remoteDatasource.watchProfile(uid).asyncMap((profile) async {
        _friendsCache.put(profile);
        await _localDatasource.saveFriendProfile(profile);
        return profile;
      });

  // Records the load of a friend's profile for BQ20. It is not awaited: without
  // connection Firestore keeps the event and sends it when the network returns
  void logFriendProfileLoad(
    String viewerUid, {
    required ProfileLoadSource source,
    required double loadMs,
  }) {
    _remoteDatasource
        .logProfileLoad(viewerUid, source: source, loadMs: loadMs)
        .catchError((Object e) =>
            debugPrint('[ProfileRepository] logProfileLoad failed: $e'));
  }

  // Saves the profiles of the friends that are not on the device yet,
  // so they can be opened later without connection
  Future<void> prefetchFriendProfiles(List<String> friendUids) async {
    final savedUids = await _localDatasource.getSavedFriendUids();
    final missingUids = friendUids.where((uid) => !savedUids.contains(uid));

    // Download all missing profiles at the same time
    final profiles =
        await Future.wait(missingUids.map(_remoteDatasource.fetchProfile));
    for (final profile in profiles) {
      await _localDatasource.saveFriendProfile(profile);
    }
  }

  // Crops and compresses the photo picked from the camera or gallery
  // and keeps it as a file on the device
  Future<Uint8List> compressAndSavePhoto(String uid, Uint8List bytes) async {
    final photo = await _photoCompressor.compress(bytes);
    await _photoStorage.savePhoto(uid, photo);
    return photo;
  }

  // Uploads the compressed photo and returns its URL
  Future<String> uploadPhoto(String uid, Uint8List photo) async {
    final photoUrl = await _remoteDatasource.uploadPhoto(uid, photo);
    await _localDatasource.setPendingPhoto(uid, false);
    await _updateStoredOwnProfile(
      uid,
      (profile) => profile.copyWith(photoUrl: photoUrl),
    );
    return photoUrl;
  }

  // Removes the photo saved on the device, so it is not shown or uploaded anymore
  Future<void> removeLocalPhoto(String uid) => _photoStorage.deletePhoto(uid);

  // Removes the photo from Storage and the profile
  Future<void> deletePhoto(String uid) async {
    await _remoteDatasource.deletePhoto(uid);
    await _localDatasource.setPendingPhoto(uid, false);
    await _updateStoredOwnProfile(
      uid,
      (profile) => profile.copyWith(removePhoto: true),
    );
  }

  // Lets the worker make the photo in Storage match the device when there is
  // connection: it uploads the saved file, or removes the photo if there is no file
  Future<void> queuePhotoSync(String uid) async {
    await _localDatasource.setPendingPhoto(uid, true);
    await ProfileSyncWorker.schedule(uid);
  }

  // Changes the name of the user
  Future<void> updateDisplayName(String uid, String displayName) async {
    await _remoteDatasource.updateDisplayName(uid, displayName);
    await _updateStoredOwnProfile(
      uid,
      (profile) => profile.copyWith(displayName: displayName),
    );
  }

  // Keeps the new name on the device and lets the worker send it later
  Future<void> queueDisplayName(String uid, String displayName) async {
    await _localDatasource.savePendingName(uid, displayName);
    await ProfileSyncWorker.schedule(uid);
  }

  // Sends the name and photo changed offline. Called by the sync worker
  Future<void> syncPendingChanges(String uid) async {
    final pendingName = await _localDatasource.getPendingName(uid);
    if (pendingName != null) {
      await updateDisplayName(uid, pendingName);
      await _localDatasource.clearPendingName(uid, pendingName);
    }

    if (await _localDatasource.hasPendingPhoto(uid)) {
      final photo = await _photoStorage.readPhoto(uid);
      if (photo == null) {
        await deletePhoto(uid);
      } else {
        await uploadPhoto(uid, photo);
      }
    }
  }

  // Shows the name and photo changed offline instead of the ones in Firestore
  Future<ProfileModel> _withPendingChanges(ProfileModel profile) async {
    final pendingName = await _localDatasource.getPendingName(profile.uid);
    var result = pendingName == null
        ? profile
        : profile.copyWith(displayName: pendingName);

    // A photo removed offline is still in Firestore until the worker removes it
    if (await _localDatasource.hasPendingPhoto(profile.uid) &&
        await _photoStorage.readPhoto(profile.uid) == null) {
      result = result.copyWith(removePhoto: true);
    }
    return result;
  }

  // Keeps the saved own profile equal to Firestore after a change
  Future<void> _updateStoredOwnProfile(
    String uid,
    ProfileModel Function(ProfileModel) update,
  ) async {
    final stored = await _localDatasource.getOwnProfile(uid);
    if (stored != null) await _localDatasource.saveOwnProfile(update(stored));
  }
}

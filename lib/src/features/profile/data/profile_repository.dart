import 'dart:typed_data';

import '../model/profile_model.dart';
import 'profile_local_datasource.dart';
import 'profile_lru_cache.dart';
import 'profile_photo_compressor.dart';
import 'profile_photo_storage.dart';
import 'profile_remote_datasource.dart';

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

  // Gets a friend's profile from memory if it was seen in the last minutes
  ProfileModel? getCachedFriendProfile(String uid) => _friendsCache.get(uid);

  // Gets the last saved own profile, or null if it was never saved
  Future<ProfileModel?> getStoredOwnProfile(String uid) =>
      _localDatasource.getOwnProfile(uid);

  // Gets the last saved profile of a friend, or null if it was never saved
  Future<ProfileModel?> getStoredFriendProfile(String uid) =>
      _localDatasource.getFriendProfile(uid);

  // Gets the photo saved on the device, or null if there is none
  Future<Uint8List?> getStoredPhoto(String uid) =>
      _photoStorage.readPhoto(uid);

  // Downloads the own profile and saves it on the device
  Future<ProfileModel> refreshOwnProfile(String uid) async {
    final profile = await _remoteDatasource.fetchProfile(uid);
    await _localDatasource.saveOwnProfile(profile);
    return profile;
  }

  // Emits a friend's profile every time it changes and saves each version
  Stream<ProfileModel> watchFriendProfile(String uid) =>
      _remoteDatasource.watchProfile(uid).asyncMap((profile) async {
        _friendsCache.put(profile);
        await _localDatasource.saveFriendProfile(profile);
        return profile;
      });

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
    await _updateStoredOwnProfile(
      uid,
      (profile) => profile.copyWith(photoUrl: photoUrl),
    );
    return photoUrl;
  }

  // Changes the name of the user
  Future<void> updateDisplayName(String uid, String displayName) async {
    await _remoteDatasource.updateDisplayName(uid, displayName);
    await _updateStoredOwnProfile(
      uid,
      (profile) => profile.copyWith(displayName: displayName),
    );
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

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/profile_repository.dart';
import '../model/profile_model.dart';
import 'profile_ui_state.dart';

class ProfileViewModel extends ChangeNotifier {
  // Max length of the display name
  static const int maxNameLength = 20;

  // Handles the profiles
  final ProfileRepository _repository;

  // Handles the current authenticated user
  final FirebaseAuth _auth;

  // User whose profile is shown. Null means the logged user
  final String? uid;

  // Stores the current state of the profile screen
  ProfileUiState _state = const ProfileUiState();

  // Provides the current state to the View
  ProfileUiState get state => _state;

  // Listens for changes in a friend's profile
  StreamSubscription<ProfileModel>? _profileSubscription;

  // Listens for connection changes to update the screen when the network comes back
  StreamSubscription<bool>? _connectionSubscription;

  // The photo upload can end after the screen is closed
  bool _isDisposed = false;

  // The repository comes from the app so its memory cache is shared by all screens
  ProfileViewModel(
    this._repository, {
    this.uid,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance {
    _connectionSubscription =
        _repository.watchConnection().listen(_onConnectionChanged);
  }

  void _onConnectionChanged(bool isOnline) {
    if (!isOnline) {
      _state = _state.copyWith(isOffline: true, errorMessage: _offlineMessage());
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isOffline: false);
    notifyListeners();

    // A friend's Stream resumes by itself. The own profile is downloaded again,
    // while the worker sends the changes made offline
    if (_state.isOwnProfile) loadProfile();
  }

  // Message that explains what is shown without connection
  String _offlineMessage() {
    final hasProfile = _state.profile != null;
    if (_state.isOwnProfile) {
      return hasProfile
          ? "You're offline. Showing your saved profile"
          : "You're offline. Connect to the internet to see your profile";
    }
    return hasProfile
        ? "You're offline. Showing the last saved profile"
        : "You're offline. This profile will load when you're back online";
  }

  // Loads the profile of the friend, or of the logged user if no uid was given
  Future<void> loadProfile() async {
    final currentUid = _auth.currentUser?.uid;
    final uid = this.uid ?? currentUid;
    if (uid == null) {
      _state = _state.copyWith(errorMessage: 'Log in to see the profile');
      notifyListeners();
      return;
    }

    // Avoid running two loads at the same time
    if (_state.isLoading) return;

    _state = _state.copyWith(isLoading: true, isOwnProfile: uid == currentUid);
    notifyListeners();

    if (_state.isOwnProfile) {
      await _loadOwnProfile(uid);
    } else {
      await _loadFriendProfile(uid);
    }
  }

  Future<void> _loadOwnProfile(String uid) async {
    // Update the screen when the worker sends the changes made offline
    _repository.listenForSyncFinished(_onSyncFinished);

    String? errorMessage;
    try {
      // Show the last saved profile (SharedPreferences) and photo (file) right away
      _state = _state.copyWith(
        profile: await _repository.getStoredOwnProfile(uid),
        localPhoto: await _repository.getStoredPhoto(uid),
        hasPendingChanges: await _repository.hasPendingChanges(uid),
      );
      notifyListeners();

      final isOnline = await _repository.isOnline();
      _state = _state.copyWith(isOffline: !isOnline);

      if (!isOnline) {
        errorMessage = _offlineMessage();
      } else {
        final profile = await _repository.refreshOwnProfile(uid);
        _state = _state.copyWith(profile: profile);
      }
    } catch (e) {
      debugPrint('[ProfileViewModel] loadOwnProfile failed: $e');
      errorMessage = _state.profile == null
          ? "We couldn't load your profile. Try again"
          : "We couldn't update your profile. Showing your saved one";
    } finally {
      // Always hide the loading state, even if something failed
      _state = _state.copyWith(isLoading: false, errorMessage: errorMessage);
      notifyListeners();
    }
  }

  Future<void> _loadFriendProfile(String uid) async {
    // A fresh profile in memory is shown without the loading state.
    // Otherwise, show the last saved version (SQLite) while Firestore answers
    final cachedProfile = _repository.getCachedFriendProfile(uid);
    if (cachedProfile != null) {
      _state = _state.copyWith(profile: cachedProfile, isLoading: false);
    } else {
      final stored = await _repository.getStoredFriendProfile(uid);
      _state = _state.copyWith(
        profile: stored?.profile,
        lastUpdated: stored?.updatedAt,
      );
    }

    // Without connection there is nothing else to wait for
    if (!await _repository.isOnline()) {
      _state = _state.copyWith(
        isOffline: true,
        isLoading: false,
        errorMessage: _offlineMessage(),
      );
    }
    notifyListeners();

    // A friend's streak and pet can change while the screen is open, so listen to them.
    // Offline it stays quiet and starts sending data when the connection comes back
    _watchProfile(uid);
  }

  // Updates the screen every time the profile changes in Firestore
  void _watchProfile(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = _repository.watchFriendProfile(uid).listen(
      (profile) {
        _state = _state.copyWith(
          profile: profile,
          lastUpdated: DateTime.now(),
          isOffline: false,
          isLoading: false,
        );
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[ProfileViewModel] watchProfile failed: $e');
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: _state.profile == null
              ? "We couldn't load this profile. Try again"
              : "We couldn't update this profile. Showing the last saved one",
        );
        notifyListeners();
      },
    );
  }

  // Shows the profile saved by the worker after it sent the pending changes
  Future<void> _onSyncFinished() async {
    final uid = _state.profile?.uid;
    if (uid == null || _isDisposed) return;

    final storedProfile = await _repository.getStoredOwnProfile(uid);
    final hasPendingChanges = await _repository.hasPendingChanges(uid);
    if (_isDisposed) return;

    // The offline message is cleared because the changes were sent
    _state = _state.copyWith(
      profile: storedProfile,
      hasPendingChanges: hasPendingChanges,
    );
    notifyListeners();
  }

  // Compresses the photo picked by the user and uploads it.
  // Without connection the photo stays on the device and the worker uploads it later
  Future<void> changePhoto(Uint8List bytes) async {
    final profile = _state.profile;
    if (!_state.isOwnProfile || profile == null || _state.isUploadingPhoto) {
      return;
    }

    _state = _state.copyWith(isUploadingPhoto: true);
    notifyListeners();

    final Uint8List photo;
    try {
      photo = await _repository.compressAndSavePhoto(profile.uid, bytes);
    } catch (e) {
      debugPrint('[ProfileViewModel] compressPhoto failed: $e');
      _state = _state.copyWith(
        isUploadingPhoto: false,
        errorMessage: "We couldn't read that photo. Try another one",
      );
      notifyListeners();
      return;
    }

    // Show the new photo right away, without waiting for the upload
    _state = _state.copyWith(localPhoto: photo);
    notifyListeners();

    if (!await _repository.isOnline()) {
      await _repository.queuePhotoSync(profile.uid);
      _state = _state.copyWith(
        isUploadingPhoto: false,
        hasPendingChanges: true,
        isOffline: true,
        errorMessage:
            "You're offline. Your photo will upload when you're back online",
      );
      notifyListeners();
      return;
    }

    // The upload is not awaited, the handlers update the screen when it ends
    _repository.uploadPhoto(profile.uid, photo).then((photoUrl) {
      if (_isDisposed) return;
      _state = _state.copyWith(
        profile: _state.profile?.copyWith(photoUrl: photoUrl),
        isUploadingPhoto: false,
      );
      notifyListeners();
    }).catchError((Object e) async {
      debugPrint('[ProfileViewModel] uploadPhoto failed: $e');
      // The photo is already on the device, so the worker retries the upload
      await _repository.queuePhotoSync(profile.uid);
      if (_isDisposed) return;
      _state = _state.copyWith(
        isUploadingPhoto: false,
        hasPendingChanges: true,
        errorMessage:
            "We couldn't upload your photo. We'll try again automatically",
      );
      notifyListeners();
    });
  }

  // Removes the profile photo.
  // Without connection the photo is hidden right away and the worker removes it later
  Future<void> removePhoto() async {
    final profile = _state.profile;
    if (!_state.isOwnProfile || profile == null || _state.isUploadingPhoto) {
      return;
    }

    // Show the profile without photo right away
    _state = _state.copyWith(
      profile: profile.copyWith(removePhoto: true),
      removeLocalPhoto: true,
      isUploadingPhoto: true,
    );
    notifyListeners();

    String? errorMessage;
    var hasPendingChanges = _state.hasPendingChanges;
    try {
      await _repository.removeLocalPhoto(profile.uid);
      if (!await _repository.isOnline()) {
        await _repository.queuePhotoSync(profile.uid);
        hasPendingChanges = true;
        errorMessage =
            "You're offline. Your photo will be removed when you're back online";
      } else {
        await _repository.deletePhoto(profile.uid);
        hasPendingChanges = await _repository.hasPendingChanges(profile.uid);
      }
    } catch (e) {
      debugPrint('[ProfileViewModel] removePhoto failed: $e');
      // The file is already gone, so the worker retries removing it from Storage
      await _repository.queuePhotoSync(profile.uid).catchError(
          (Object e) => debugPrint('[ProfileViewModel] queuePhotoSync failed: $e'));
      hasPendingChanges = true;
      errorMessage =
          "We couldn't remove your photo. We'll try again automatically";
    } finally {
      _state = _state.copyWith(
        isUploadingPhoto: false,
        hasPendingChanges: hasPendingChanges,
        errorMessage: errorMessage,
      );
      notifyListeners();
    }
  }

  // Changes the name of the logged user.
  // Without connection the name is saved on the device and the worker sends it later
  Future<void> updateDisplayName(String name) async {
    final profile = _state.profile;
    if (!_state.isOwnProfile || profile == null || _state.isLoading) return;

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _state = _state.copyWith(errorMessage: 'Enter a name');
      notifyListeners();
      return;
    }
    if (trimmedName.length > maxNameLength) {
      _state = _state.copyWith(
        errorMessage: 'Use $maxNameLength characters or less',
      );
      notifyListeners();
      return;
    }

    if (!await _repository.isOnline()) {
      await _repository.queueDisplayName(profile.uid, trimmedName);
      _state = _state.copyWith(
        profile: profile.copyWith(displayName: trimmedName),
        hasPendingChanges: true,
        isOffline: true,
        errorMessage:
            "You're offline. Your new name will be saved when you're back online",
      );
      notifyListeners();
      return;
    }

    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    String? errorMessage;
    try {
      await _repository.updateDisplayName(profile.uid, trimmedName);
      _state = _state.copyWith(
        profile: profile.copyWith(displayName: trimmedName),
      );
    } catch (e) {
      debugPrint('[ProfileViewModel] updateDisplayName failed: $e');
      errorMessage = "We couldn't save your name. Try again";
    } finally {
      _state = _state.copyWith(isLoading: false, errorMessage: errorMessage);
      notifyListeners();
    }
  }

  // Loads and uploads can finish after the user left the screen, so skip the update then
  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    // Stop listening to Firestore, the connection and the worker when the screen is closed
    _isDisposed = true;
    _profileSubscription?.cancel();
    _connectionSubscription?.cancel();
    if (_state.isOwnProfile) _repository.stopListeningForSyncFinished();
    super.dispose();
  }
}

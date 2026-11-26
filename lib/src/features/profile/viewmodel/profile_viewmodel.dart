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

  // The photo upload can end after the screen is closed
  bool _isDisposed = false;

  ProfileViewModel({
    this.uid,
    ProfileRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? ProfileRepository(),
        _auth = auth ?? FirebaseAuth.instance;

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

    if (!_state.isOwnProfile) {
      // Show the last saved version (SQLite) while Firestore answers
      _state = _state.copyWith(
        profile: await _repository.getStoredFriendProfile(uid),
      );
      notifyListeners();

      // A friend's streak and pet can change while the screen is open, so listen to them
      _watchProfile(uid);
      return;
    }

    String? errorMessage;
    try {
      // Show the last saved profile (SharedPreferences) and photo (file) right away
      _state = _state.copyWith(
        profile: await _repository.getStoredOwnProfile(uid),
        localPhoto: await _repository.getStoredPhoto(uid),
      );
      notifyListeners();

      final profile = await _repository.refreshOwnProfile(uid);
      _state = _state.copyWith(profile: profile);
    } catch (e) {
      debugPrint('[ProfileViewModel] loadProfile failed: $e');
      errorMessage = _state.profile == null
          ? "We couldn't load the profile. Try again"
          : "We couldn't update the profile. Showing the last saved one";
    } finally {
      // Always hide the loading state, even if something failed
      _state = _state.copyWith(isLoading: false, errorMessage: errorMessage);
      notifyListeners();
    }
  }

  // Updates the screen every time the profile changes in Firestore
  void _watchProfile(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = _repository.watchFriendProfile(uid).listen(
      (profile) {
        _state = _state.copyWith(profile: profile, isLoading: false);
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('[ProfileViewModel] watchProfile failed: $e');
        _state = _state.copyWith(
          isLoading: false,
          errorMessage: _state.profile == null
              ? "We couldn't load the profile. Try again"
              : "We couldn't update the profile. Showing the last saved one",
        );
        notifyListeners();
      },
    );
  }

  // Compresses the photo picked by the user and uploads it
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

    // The upload is not awaited, the handlers update the screen when it ends
    _repository.uploadPhoto(profile.uid, photo).then((photoUrl) {
      if (_isDisposed) return;
      _state = _state.copyWith(
        profile: _state.profile?.copyWith(photoUrl: photoUrl),
        isUploadingPhoto: false,
      );
      notifyListeners();
    }).catchError((Object e) {
      debugPrint('[ProfileViewModel] uploadPhoto failed: $e');
      if (_isDisposed) return;
      _state = _state.copyWith(
        isUploadingPhoto: false,
        errorMessage: "We couldn't upload your photo. Try again",
      );
      notifyListeners();
    });
  }

  // Changes the name of the logged user
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

  @override
  void dispose() {
    // Stop listening to Firestore when the screen is closed
    _isDisposed = true;
    _profileSubscription?.cancel();
    super.dispose();
  }
}

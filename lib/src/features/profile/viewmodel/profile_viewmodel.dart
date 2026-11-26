import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/profile_repository.dart';
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

    String? errorMessage;
    try {
      final profile = await _repository.getProfile(uid);
      _state = _state.copyWith(profile: profile);
    } catch (e) {
      debugPrint('[ProfileViewModel] loadProfile failed: $e');
      errorMessage = "We couldn't load the profile. Try again";
    } finally {
      // Always hide the loading state, even if something failed
      _state = _state.copyWith(isLoading: false, errorMessage: errorMessage);
      notifyListeners();
    }
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
}

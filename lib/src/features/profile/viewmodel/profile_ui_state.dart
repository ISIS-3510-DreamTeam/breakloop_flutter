import 'dart:typed_data';

import '../model/profile_model.dart';

class ProfileUiState {
  // Profile shown on the screen, null until it is loaded
  final ProfileModel? profile;

  // Compressed photo shown right away while it is being uploaded
  final Uint8List? localPhoto;

  // Indicates if the profile being shown belongs to the logged user
  final bool isOwnProfile;

  // Indicates if the profile is being loaded or saved
  final bool isLoading;

  // Indicates if the new photo is being compressed or uploaded
  final bool isUploadingPhoto;

  // Indicates if the name or photo changed offline were not sent yet
  final bool hasPendingChanges;

  // When the friend's profile was last downloaded ("updated X ago")
  final DateTime? lastUpdated;

  // Indicates if the device has no connection
  final bool isOffline;

  // Stores a message for the user if something goes wrong or there is no connection
  final String? errorMessage;

  const ProfileUiState({
    this.profile,
    this.localPhoto,
    this.isOwnProfile = false,
    this.isLoading = false,
    this.isUploadingPhoto = false,
    this.hasPendingChanges = false,
    this.lastUpdated,
    this.isOffline = false,
    this.errorMessage,
  });

  // Creates a new state while keeping the values that were not changed
  ProfileUiState copyWith({
    ProfileModel? profile,
    Uint8List? localPhoto,
    bool? isOwnProfile,
    bool? isLoading,
    bool? isUploadingPhoto,
    bool? hasPendingChanges,
    DateTime? lastUpdated,
    bool? isOffline,
    String? errorMessage,
    bool removeLocalPhoto = false,
  }) {
    return ProfileUiState(
      profile: profile ?? this.profile,
      localPhoto: removeLocalPhoto ? null : localPhoto ?? this.localPhoto,
      isOwnProfile: isOwnProfile ?? this.isOwnProfile,
      isLoading: isLoading ?? this.isLoading,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      hasPendingChanges: hasPendingChanges ?? this.hasPendingChanges,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOffline: isOffline ?? this.isOffline,
      errorMessage: errorMessage,
    );
  }
}

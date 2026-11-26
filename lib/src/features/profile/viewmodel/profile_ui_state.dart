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

  // Stores an error message if something goes wrong
  final String? errorMessage;

  const ProfileUiState({
    this.profile,
    this.localPhoto,
    this.isOwnProfile = false,
    this.isLoading = false,
    this.isUploadingPhoto = false,
    this.errorMessage,
  });

  // Creates a new state while keeping the values that were not changed
  ProfileUiState copyWith({
    ProfileModel? profile,
    Uint8List? localPhoto,
    bool? isOwnProfile,
    bool? isLoading,
    bool? isUploadingPhoto,
    String? errorMessage,
  }) {
    return ProfileUiState(
      profile: profile ?? this.profile,
      localPhoto: localPhoto ?? this.localPhoto,
      isOwnProfile: isOwnProfile ?? this.isOwnProfile,
      isLoading: isLoading ?? this.isLoading,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      errorMessage: errorMessage,
    );
  }
}

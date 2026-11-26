import '../model/profile_model.dart';

class ProfileUiState {
  // Profile shown on the screen, null until it is loaded
  final ProfileModel? profile;

  // Indicates if the profile being shown belongs to the logged user
  final bool isOwnProfile;

  // Indicates if the profile is being loaded or saved
  final bool isLoading;

  // Stores an error message if something goes wrong
  final String? errorMessage;

  const ProfileUiState({
    this.profile,
    this.isOwnProfile = false,
    this.isLoading = false,
    this.errorMessage,
  });

  // Creates a new state while keeping the values that were not changed
  ProfileUiState copyWith({
    ProfileModel? profile,
    bool? isOwnProfile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProfileUiState(
      profile: profile ?? this.profile,
      isOwnProfile: isOwnProfile ?? this.isOwnProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

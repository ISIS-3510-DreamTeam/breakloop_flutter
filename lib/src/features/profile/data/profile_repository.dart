import '../model/profile_model.dart';
import 'profile_remote_datasource.dart';

/// Repository that manages the user's profile and the profiles of friends.
class ProfileRepository {
  final ProfileRemoteDatasource _remoteDatasource;

  // Uses the provided dependencies or creates the default ones
  ProfileRepository({ProfileRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? ProfileRemoteDatasource();

  // Gets the profile of any user (own or friend)
  Future<ProfileModel> getProfile(String uid) =>
      _remoteDatasource.fetchProfile(uid);

  // Changes the name of the user
  Future<void> updateDisplayName(String uid, String displayName) =>
      _remoteDatasource.updateDisplayName(uid, displayName);
}

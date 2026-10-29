import '../model/friend_model.dart';
import '../model/user_profile_model.dart';
import 'friends_remote_datasource.dart';

/// Repository that manages the user's profile and friends
class FriendsRepository {
  final FriendsRemoteDatasource _remoteDatasource;

  // Uses the provided remote datasource or creates a default one
  FriendsRepository({FriendsRemoteDatasource? remoteDatasource})
      : _remoteDatasource = remoteDatasource ?? FriendsRemoteDatasource();

  // Gets the user's profile, creating it with a friend code if needed
  Future<UserProfileModel> ensureProfile({
    required String uid,
    required String email,
  }) async {
    final profile = await _remoteDatasource.fetchProfile(uid);
    return profile ??
        await _remoteDatasource.createProfile(uid: uid, email: email);
  }

  // Adds the owner of the code as a friend of the user
  Future<AddFriendResult> addFriendByCode({
    required String uid,
    required String code,
  }) async {
    final friendUid =
        await _remoteDatasource.findUidByCode(code.trim().toUpperCase());

    if (friendUid == null) return AddFriendResult.notFound;
    if (friendUid == uid) return AddFriendResult.ownCode;

    await _remoteDatasource.addFriendship(uid, friendUid);
    return AddFriendResult.added;
  }

  // Gets the user's friends with their streak and pet level
  Future<List<FriendModel>> getFriends(String uid) async {
    final friendUids = await _remoteDatasource.fetchFriendUids(uid);
    final friends = <FriendModel>[];

    // Load each friend one by one
    for (final friendUid in friendUids) {
      friends.add(await _remoteDatasource.fetchFriend(friendUid));
    }
    return friends;
  }
}

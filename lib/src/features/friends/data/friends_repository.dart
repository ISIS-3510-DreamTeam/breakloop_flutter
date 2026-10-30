import 'package:connectivity_plus/connectivity_plus.dart';

import '../model/friend_model.dart';
import '../model/user_profile_model.dart';
import 'friends_local_datasource.dart';
import 'friends_remote_datasource.dart';

/// Repository that manages the user's profile and friends.
/// It decides if data comes from memory, the device or Firestore.
class FriendsRepository {
  final FriendsRemoteDatasource _remoteDatasource;
  final FriendsLocalDatasource _localDatasource;
  final Connectivity _connectivity;

  // Time the in-memory friends list is considered up to date
  static const Duration _cacheDuration = Duration(minutes: 5);

  // In-memory cache: friends by uid, owner of the list and when it was downloaded
  final Map<String, FriendModel> _friendsCache = {};
  String? _cacheOwnerUid;
  DateTime? _cachedAt;

  // Uses the provided dependencies or creates the default ones
  FriendsRepository({
    FriendsRemoteDatasource? remoteDatasource,
    FriendsLocalDatasource? localDatasource,
    Connectivity? connectivity,
  })  : _remoteDatasource = remoteDatasource ?? FriendsRemoteDatasource(),
        _localDatasource = localDatasource ?? FriendsLocalDatasource(),
        _connectivity = connectivity ?? Connectivity();

  // Checks if the device has a network connection before calling Firestore
  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  // Emits true when the connection comes back and false when it is lost
  Stream<bool> watchConnection() => _connectivity.onConnectivityChanged
      .map((results) => !results.contains(ConnectivityResult.none))
      .distinct();

  // Gets the user's profile, creating it with a friend code if needed.
  // Returns null if it was never created and there is no connection.
  Future<UserProfileModel?> ensureProfile({
    required String uid,
    required String email,
  }) async {
    // The profile does not change, so the local copy is enough
    final localProfile = await _localDatasource.getProfile(uid);
    if (localProfile != null) return localProfile;

    // Creating the code needs a transaction, which only works online
    if (!await isOnline()) return null;

    final profile = await _remoteDatasource.fetchProfile(uid) ??
        await _remoteDatasource.createProfile(uid: uid, email: email);
    await _localDatasource.saveProfile(profile);
    return profile;
  }

  // Adds the owner of the code as a friend of the user
  Future<AddFriendResult> addFriendByCode({
    required String uid,
    required String code,
  }) async {
    final friendUid = await _remoteDatasource.findUidByCode(code);

    if (friendUid == null) return AddFriendResult.notFound;
    if (friendUid == uid) return AddFriendResult.ownCode;

    await _remoteDatasource.addFriendship(uid, friendUid);
    return AddFriendResult.added;
  }

  // Gets the codes added while offline
  Future<List<String>> getPendingCodes(String uid) =>
      _localDatasource.getPendingCodes(uid);

  // Saves a code to add the friend when the connection comes back
  Future<List<String>> queuePendingCode({
    required String uid,
    required String code,
  }) async {
    final codes = await _localDatasource.getPendingCodes(uid);

    // Skip repeated codes so the same request is not sent twice
    if (!codes.contains(code)) {
      codes.add(code);
      await _localDatasource.savePendingCodes(uid, codes);
    }
    return codes;
  }

  // Sends the queued codes and returns the ones that could not be added
  Future<List<String>> syncPendingCodes(String uid) async {
    final codes = await _localDatasource.getPendingCodes(uid);
    final remainingCodes = <String>[];
    final invalidCodes = <String>[];

    for (final code in codes) {
      try {
        final result = await addFriendByCode(uid: uid, code: code);
        if (result != AddFriendResult.added) invalidCodes.add(code);
      } catch (e) {
        // Keep the code to try again on the next connection
        remainingCodes.add(code);
      }
    }

    await _localDatasource.savePendingCodes(uid, remainingCodes);
    return invalidCodes;
  }

  // Gets the last known friends: memory first, then the device.
  // Returns null if the list was never downloaded.
  Future<List<FriendModel>?> getStoredFriends(String uid) async {
    if (_cacheOwnerUid == uid && _cachedAt != null) {
      return _friendsCache.values.toList();
    }

    final friends = await _localDatasource.getFriends(uid);
    final lastUpdated = await _localDatasource.getLastUpdated(uid);
    if (friends == null || lastUpdated == null) return null;

    _fillCache(uid, friends, lastUpdated);
    return friends;
  }

  // When the friends list was last downloaded from Firestore
  DateTime? lastUpdated(String uid) =>
      _cacheOwnerUid == uid ? _cachedAt : null;

  // Checks if the cached list is recent enough to skip Firestore
  bool isCacheFresh(String uid) {
    final cachedAt = _cachedAt;
    return _cacheOwnerUid == uid &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheDuration;
  }

  // Downloads the friends from Firestore and saves them in memory and on the device
  Future<List<FriendModel>> refreshFriends(String uid) async {
    final friendUids = await _remoteDatasource.fetchFriendUids(uid);

    // Load all friends at the same time instead of one by one
    final friends = await Future.wait(
      friendUids.map(_remoteDatasource.fetchFriend),
    );

    final now = DateTime.now();
    _fillCache(uid, friends, now);
    await _localDatasource.saveFriends(uid, friends, now);
    return friends;
  }

  // Replaces the in-memory cache with a new friends list
  void _fillCache(String uid, List<FriendModel> friends, DateTime fetchedAt) {
    _friendsCache
      ..clear()
      ..addEntries(friends.map((f) => MapEntry(f.uid, f)));
    _cacheOwnerUid = uid;
    _cachedAt = fetchedAt;
  }
}

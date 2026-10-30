import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/friend_model.dart';
import '../model/user_profile_model.dart';

// Handles the communication with Firestore for friends.
class FriendsRemoteDatasource {
  final FirebaseFirestore _firestore;

  // Characters used for friend codes (without 0/O and 1/I to avoid confusion)
  static const String _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 4;

  // Reads go to the server so offline errors are not hidden by Firestore's own cache
  static const GetOptions _serverOnly = GetOptions(source: Source.server);

  // Uses the provided Firestore instance or the default one.
  FriendsRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Gets the user's profile, or null if it has no friend code yet.
  Future<UserProfileModel?> fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get(_serverOnly);
    final data = doc.data();

    if (data == null || data['friendCode'] == null) return null;
    return UserProfileModel.fromFirestore(data, doc.id);
  }

  // Creates the user's profile with a unique friend code.
  Future<UserProfileModel> createProfile({
    required String uid,
    required String email,
  }) async {
    final random = Random.secure();

    // Try new codes until one is not taken
    while (true) {
      final code = List.generate(
        _codeLength,
        (_) => _codeChars[random.nextInt(_codeChars.length)],
      ).join();

      final profile = UserProfileModel(
        uid: uid,
        email: email,
        displayName: email.split('@').first,
        friendCode: code,
      );

      // Reserve the code and save the profile in a single transaction
      final created = await _firestore.runTransaction((transaction) async {
        final codeRef = _firestore.collection('friendCodes').doc(code);
        final codeDoc = await transaction.get(codeRef);
        if (codeDoc.exists) return false;

        transaction.set(codeRef, {'uid': uid});
        transaction.set(
          _firestore.collection('users').doc(uid),
          profile.toFirestore(),
          SetOptions(merge: true),
        );
        return true;
      });

      if (created) return profile;
    }
  }

  // Gets the uid that owns a friend code, or null if it does not exist.
  Future<String?> findUidByCode(String code) async {
    final doc = await _firestore
        .collection('friendCodes')
        .doc(code)
        .get(_serverOnly);
    return doc.data()?['uid'] as String?;
  }

  // Saves the friendship in both users' friends collections.
  Future<void> addFriendship(String uid, String friendUid) async {
    final batch = _firestore.batch();
    final since = FieldValue.serverTimestamp();

    batch.set(_friendsRef(uid).doc(friendUid), {'since': since});
    batch.set(_friendsRef(friendUid).doc(uid), {'since': since});

    await batch.commit();
  }

  // Gets the uids of the user's friends.
  Future<List<String>> fetchFriendUids(String uid) async {
    final snapshot = await _friendsRef(uid).get(_serverOnly);
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // Gets a friend's name, streak and pet level.
  Future<FriendModel> fetchFriend(String friendUid) async {
    final userRef = _firestore.collection('users').doc(friendUid);

    // Read the profile and the progress at the same time
    final docs = await Future.wait([
      userRef.get(_serverOnly),
      userRef.collection('progress').doc('current').get(_serverOnly),
    ]);

    return FriendModel.fromFirestore(
      uid: friendUid,
      profile: docs[0].data() ?? {},
      progress: docs[1].data() ?? {},
    );
  }

  CollectionReference<Map<String, dynamic>> _friendsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('friends');
}

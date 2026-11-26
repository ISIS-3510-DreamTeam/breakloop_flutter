import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/profile_model.dart';

// Handles the communication with Firestore for profiles.
class ProfileRemoteDatasource {
  final FirebaseFirestore _firestore;

  // Reads go to the server so offline errors are not hidden by Firestore's own cache
  static const GetOptions _serverOnly = GetOptions(source: Source.server);

  // Uses the provided Firestore instance or the default one.
  ProfileRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Gets the user's name, photo, friend code, streak and pet level.
  Future<ProfileModel> fetchProfile(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

    // Read the profile and the progress at the same time
    final docs = await Future.wait([
      userRef.get(_serverOnly),
      userRef.collection('progress').doc('current').get(_serverOnly),
    ]);

    return ProfileModel.fromFirestore(
      uid: uid,
      profile: docs[0].data() ?? {},
      progress: docs[1].data() ?? {},
    );
  }

  // Saves the new display name of the user.
  Future<void> updateDisplayName(String uid, String displayName) {
    return _firestore
        .collection('users')
        .doc(uid)
        .update({'displayName': displayName});
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/flagged_app.dart';

// Handles the communication with Firestore for the flagged apps.
class FlaggedAppsRemoteDatasource {
  final FirebaseFirestore _firestore;

  // Uses the provided Firestore instance or the default one.
  FlaggedAppsRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Saves a flagged app in users/{uid}/flaggedApps/{packageName}
  Future<void> saveFlaggedApp(String uid, FlaggedApp app) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('flaggedApps')
        .doc(app.packageName)
        .set(app.toFirestore());
  }

  Future<void> deleteFlaggedApp(String uid, String packageName) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('flaggedApps')
        .doc(packageName)
        .delete();
  }
}

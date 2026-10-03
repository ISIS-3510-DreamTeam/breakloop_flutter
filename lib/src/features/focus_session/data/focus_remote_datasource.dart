import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/focus_session_model.dart';

// Handles the communication with Firestore for focus sessions.
class FocusRemoteDatasource {
  final FirebaseFirestore _firestore;

  // Uses the provided Firestore instance or the default one.
  FocusRemoteDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Saves a focus session in the user's Firestore collection.
  Future<void> saveSession(FocusSessionModel session) async {
    // Make sure the session has a valid user ID.
    if (session.userId.isEmpty) {
      throw Exception('UserId cannot be empty when syncing with Firestore');
    }

    // Save the session inside the user's focus sessions.
    await _firestore
        .collection('users')
        .doc(session.userId)
        .collection('focus_sessions')
        .doc(session.sessionId)
        .set(session.toFirestore());
  }

  // Gets all the focus sessions stored for a user.
  Future<List<FocusSessionModel>> fetchRemoteSessions(
      String userId) async {
    // Get the user's focus sessions ordered from newest to oldest.
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('focus_sessions')
        .orderBy('startedAt', descending: true)
        .get();

    // Convert each Firestore document into a FocusSessionModel.
    return snapshot.docs
        .map((doc) => FocusSessionModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }
}
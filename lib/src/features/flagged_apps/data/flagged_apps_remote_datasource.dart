import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

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

  // Sends the usage of a day to the backend, the same POST api/users/{uid}/usage of the Kotlin app.
  // The backend saves it in users/{uid}/usage/{date}
  Future<void> postDailyUsage(User user, Map<String, Object?> usage) async {
    final token = await user.getIdToken();
    final response = await http.post(
      Uri.parse('$_baseUrl/api/users/${user.uid}/usage'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(usage),
    );
    if (response.statusCode >= 300) {
      throw Exception('POST usage failed: ${response.statusCode} ${response.body}');
    }
  }

  static const _baseUrl = 'https://breakloop-backend-14746672383.southamerica-west1.run.app';
}

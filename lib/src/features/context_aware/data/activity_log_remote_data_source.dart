import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../model/activity_log_entry.dart';

//Sends the activity logs to the backend, same endpoint and body as ActivityLogApi in the Kotlin app
class ActivityLogRemoteDataSource {
  static const _baseUrl = 'https://breakloop-backend-14746672383.southamerica-west1.run.app';

  final http.Client _client;
  final FirebaseAuth _auth;

  ActivityLogRemoteDataSource({http.Client? client, FirebaseAuth? auth})
      : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  //Returns false when there is no session, so the logs stay queued until the user logs in.
  //Throws if the request fails, so the caller keeps them queued too
  Future<bool> upload(List<ActivityLogEntry> logs) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdToken();

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/users/${user.uid}/activity-logs/batch'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode([for (final log in logs) log.toDto()]),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('Activity logs upload failed with ${response.statusCode}: ${response.body}');
    }
    return true;
  }
}

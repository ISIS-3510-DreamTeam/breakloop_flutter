import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const String backUrl = 'https://breakloop-backend-14746672383.southamerica-west1.run.app/';

// Streak in the cloud: PUT and GET /api/users/{uid}/progress.
class ProgressRemoteDatasource {
  ProgressRemoteDatasource({
    http.Client? client,
    FirebaseAuth? auth,
    String baseUrl = backUrl,
  })  : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance,
        _baseUrl = Uri.parse(baseUrl);

  final http.Client _client;
  final FirebaseAuth _auth;
  final Uri _baseUrl;

  // Sends the streak and the longest streak. The backend keeps the other fields as they are.
  Future<void> putStreak({required int streak, required int longestStreak}) async {
    final uid = _currentUid();
    final res = await _client.put(
      _baseUrl.resolve('api/users/$uid/progress'),
      headers: await _headers(),
      body: jsonEncode({'streak': streak, 'longestStreak': longestStreak}),
    );
    _ensureSuccess(res);
  }

  // Reads the streak saved in the cloud. A user without data returns zeros.
  Future<({int streak, int longestStreak})> fetchStreak() async {
    final uid = _currentUid();
    final res = await _client.get(
      _baseUrl.resolve('api/users/$uid/progress'),
      headers: await _headers(),
    );
    _ensureSuccess(res);

    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (
    streak: json['streak'] as int? ?? 0,
    longestStreak: json['longestStreak'] as int? ?? 0,
    );
  }

  String _currentUid() {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    return user.uid;
  }

  Future<Map<String, String>> _headers() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in user');
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  void _ensureSuccess(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}', uri: res.request?.url);
    }
  }
}
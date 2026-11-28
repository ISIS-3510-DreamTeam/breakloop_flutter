import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../pet/data/pet_api.dart' show backUrl;

// Unlocks in the cloud: /api/users/{uid}/achievements. Every call sends the Firebase token.
class AchievementsRemoteDatasource {
  AchievementsRemoteDatasource({
    http.Client? client,
    FirebaseAuth? auth,
    String baseUrl = backUrl,
  })  : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance,
        _baseUrl = Uri.parse(baseUrl);

  final http.Client _client;
  final FirebaseAuth _auth;
  final Uri _baseUrl;

  // PUT: the backend keeps the earliest date if the same achievement arrives twice.
  Future<void> unlock({required String achievementId, required int unlockedAt}) async {
    final uid = _currentUid();
    final res = await _client.put(
      _baseUrl.resolve('api/users/$uid/achievements/$achievementId'),
      headers: await _headers(),
      body: jsonEncode({'unlockedAt': unlockedAt}),
    );
    _ensureSuccess(res);
  }

  // GET: achievement id → unlock time in epoch milliseconds.
  Future<Map<String, int>> fetchUnlocks() async {
    final uid = _currentUid();
    final res = await _client.get(
      _baseUrl.resolve('api/users/$uid/achievements'),
      headers: await _headers(),
    );
    _ensureSuccess(res);

    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    final result = <String, int>{};
    for (final item in list) {
      final json = item as Map<String, dynamic>;
      result[json['id'] as String] = json['unlockedAt'] as int;
    }
    return result;
  }

  // DELETE: removes every cloud unlock of the user. Developer tools only.
  Future<void> deleteAll() async {
    final uid = _currentUid();
    final res = await _client.delete(
      _baseUrl.resolve('api/users/$uid/achievements'),
      headers: await _headers(),
    );
    _ensureSuccess(res);
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
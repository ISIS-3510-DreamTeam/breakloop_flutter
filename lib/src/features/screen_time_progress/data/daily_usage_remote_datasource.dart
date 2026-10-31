import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

//Sends the usage of a day to the backend, the same POST api/users/{uid}/usage of the Kotlin app.
//The backend saves it in users/{uid}/usage/{date}, so sending a day again overwrites it
class DailyUsageRemoteDatasource {
  static const _baseUrl = 'https://breakloop-backend-14746672383.southamerica-west1.run.app';

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
}

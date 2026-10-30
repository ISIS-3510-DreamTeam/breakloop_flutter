import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../model/suggestion_interaction.dart';

//Sends the suggestion interactions to the backend, same endpoint and body as SuggestionInteractionApi in the Kotlin app
class SuggestionInteractionRemoteDataSource {
  static const _baseUrl = 'https://breakloop-backend-14746672383.southamerica-west1.run.app';

  final http.Client _client;
  final FirebaseAuth _auth;

  SuggestionInteractionRemoteDataSource({http.Client? client, FirebaseAuth? auth})
      : _client = client ?? http.Client(),
        _auth = auth ?? FirebaseAuth.instance;

  //Returns false when there is no session, so the interactions stay queued until the user logs in.
  //Throws if the request fails, so the caller keeps them queued too
  Future<bool> upload(List<SuggestionInteraction> interactions) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdToken();

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/users/${user.uid}/suggestion-interactions/batch'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode([for (final interaction in interactions) interaction.toDto()]),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException('Suggestion interactions upload failed with ${response.statusCode}: ${response.body}');
    }
    return true;
  }
}

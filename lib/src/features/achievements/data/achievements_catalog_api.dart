import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../pet/data/pet_api.dart' show backUrl;

// GET /api/achievements. Public endpoint.
class AchievementsCatalogApi {
  AchievementsCatalogApi({http.Client? client, String baseUrl = backUrl})
      : _client = client ?? http.Client(),
        _baseUrl = Uri.parse(baseUrl);

  final http.Client _client;
  final Uri _baseUrl;

  Uri get baseUrl => _baseUrl;

  Future<String> fetchCatalogJson() async {
    final res = await _client.get(_baseUrl.resolve('api/achievements'));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}', uri: res.request?.url);
    }
    return utf8.decode(res.bodyBytes);
  }

  void dispose() => _client.close();
}
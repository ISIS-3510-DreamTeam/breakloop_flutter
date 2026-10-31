import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../model/pet_dto.dart';
import '../model/pet_state_request.dart';


const String backUrl =
    'https://breakloop-backend-14746672383.southamerica-west1.run.app/';

class PetApi {

  PetApi({http.Client? client, String baseUrl = backUrl})
      : _client = client ?? http.Client(),
        _baseUrl = Uri.parse(baseUrl);

  final http.Client _client;
  final Uri _baseUrl;

  Future<List<PetDto>> getPets() async {
    final res = await _client.get(_baseUrl.resolve('api/pets'));
    _ensureSuccess(res);
    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List<dynamic>;
    return [for (final e in list) PetDto.fromJson(e as Map<String, dynamic>)];
  }

  //Returns the raw response. The repository checks the code.
  Future<http.Response> updatePetState(String uid, PetStateRequest state) {
    return _client.put(
      _baseUrl.resolve('api/users/$uid/pet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(state.toJson()),
    );
  }

  // Equivalent to @Url, the relative route y resolved against the baseUrl.
  Future<Uint8List> downloadFile(String path) async {
    final res = await _client.get(_baseUrl.resolve(path));
    _ensureSuccess(res);
    return res.bodyBytes;
  }

  void _ensureSuccess(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw HttpException('HTTP ${res.statusCode}', uri: res.request?.url);
    }
  }

  void dispose() => _client.close();
}
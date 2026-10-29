import 'dart:convert';

import 'package:http/http.dart' as http;

//Client of the Open-Meteo API (free, no API key)
class WeatherApi {
  static const _host = 'api.open-meteo.com';

  //Returns the WMO code of the current weather at the given coordinates
  Future<int> getCurrentWeatherCode(double latitude, double longitude) async {
    final uri = Uri.https(_host, '/v1/forecast', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'current': 'weather_code',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw http.ClientException('Open-Meteo returned ${response.statusCode}', uri);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final current = json['current'] as Map<String, dynamic>;
    return current['weather_code'] as int;
  }
}

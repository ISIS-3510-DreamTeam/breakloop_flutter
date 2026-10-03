import '../model/weather_condition.dart';

abstract interface class WeatherRepository {
  //Null when the weather is not available (no permission, no connection, or the request took too long)
  Future<WeatherCondition?> getCurrentWeather();
}

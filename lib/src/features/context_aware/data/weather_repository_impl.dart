import '../model/weather_condition.dart';
import 'location_data_source.dart';
import 'weather_api.dart';
import 'weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  //The weather does not change much in a few minutes, so we keep it for 30 minutes
  static const _cacheDuration = Duration(minutes: 30);

  final LocationDataSource _locationDataSource;
  final WeatherApi _weatherApi;

  WeatherCondition? _cachedCondition;
  DateTime? _cachedAt;

  WeatherRepositoryImpl(this._locationDataSource, this._weatherApi);

  @override
  Future<WeatherCondition?> getCurrentWeather() async {
    final cachedCondition = _cachedCondition;
    final cachedAt = _cachedAt;
    if (cachedCondition != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheDuration) {
      return cachedCondition;
    }

    final coordinates = await _locationDataSource.getApproximateLocation();
    if (coordinates == null) {
      return null;
    }
    try {
      final code = await _weatherApi
          .getCurrentWeatherCode(coordinates.latitude, coordinates.longitude)
          .timeout(const Duration(milliseconds: 1500));
      final condition = WeatherCondition.fromWmoCode(code);
      _cachedCondition = condition;
      _cachedAt = DateTime.now();
      return condition;
    } catch (_) {
      return null;
    }
  }
}

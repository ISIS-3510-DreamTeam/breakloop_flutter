import '../model/context_snapshot.dart';
import '../model/part_of_day.dart';
import 'activity_log_repository.dart';
import 'context_provider.dart';
import 'interests_data_source.dart';
import 'weather_repository.dart';

//Builds the current context from the clock, the available time, the weather, the user interests and the recent activities
class ContextProviderImpl implements ContextProvider {
  final InterestsDataSource _interestsDataSource;
  final ActivityLogRepository _activityLogRepository;
  final WeatherRepository _weatherRepository;
  final DateTime Function() _now;

  ContextProviderImpl(
    this._interestsDataSource,
    this._activityLogRepository,
    this._weatherRepository, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  @override
  Future<ContextSnapshot> getSnapshot(int availableMin) async {
    final now = _now();
    //The suggestion must not wait too long for the weather, so after 2.5 seconds it is built without it
    final weather = await _weatherRepository.getCurrentWeather().timeout(
      const Duration(milliseconds: 2500),
      onTimeout: () => null,
    );
    return ContextSnapshot(
      partOfDay: PartOfDay.fromHour(now.hour),
      //DateTime.weekday goes from Monday (1) to Sunday (7)
      isWeekend: now.weekday > 5,
      availableMin: availableMin,
      weather: weather,
      interests: await _interestsDataSource.getInterests(),
      recentActivityIds: await _activityLogRepository.getRecentActivityIds(3),
    );
  }
}

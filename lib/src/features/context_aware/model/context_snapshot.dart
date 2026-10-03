import 'activity_category.dart';
import 'part_of_day.dart';
import 'weather_condition.dart';

//Current context of the user, used by the recommender
class ContextSnapshot {
  final PartOfDay partOfDay;
  final bool isWeekend;
  final int availableMin;
  //Null when the weather is not available (the weather service is not connected yet)
  final WeatherCondition? weather;
  final Set<ActivityCategory> interests;
  //Most recent first
  final List<String> recentActivityIds;

  const ContextSnapshot({
    required this.partOfDay,
    required this.isWeekend,
    required this.availableMin,
    required this.weather,
    required this.interests,
    required this.recentActivityIds,
  });
}

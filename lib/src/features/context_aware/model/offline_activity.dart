import 'activity_category.dart';
import 'part_of_day.dart';
import 'weather_condition.dart';

class OfflineActivity {
  final String id;
  final String title;
  final ActivityCategory category;
  final int durationMin;
  final int xp;
  final String prompt;
  final bool isOutdoor;
  final Set<WeatherCondition> suitableWeather;
  final Set<PartOfDay> suitablePartsOfDay;

  const OfflineActivity({
    required this.id,
    required this.title,
    required this.category,
    required this.durationMin,
    required this.xp,
    required this.prompt,
    required this.isOutdoor,
    required this.suitableWeather,
    required this.suitablePartsOfDay,
  });

  //The catalog stores the enum values in uppercase (e.g. "MOVE"), so we lowercase them before matching
  factory OfflineActivity.fromJson(Map<String, dynamic> json) {
    return OfflineActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      category: ActivityCategory.values.byName((json['category'] as String).toLowerCase()),
      durationMin: json['durationMin'] as int,
      xp: json['xp'] as int,
      prompt: json['prompt'] as String,
      isOutdoor: json['outdoor'] as bool,
      suitableWeather: {
        for (final weather in json['weather'] as List) WeatherCondition.values.byName((weather as String).toLowerCase()),
      },
      suitablePartsOfDay: {
        for (final part in json['timeOfDay'] as List) PartOfDay.values.byName((part as String).toLowerCase()),
      },
    );
  }
}

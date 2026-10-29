import 'activity_source.dart';
import 'part_of_day.dart';

//Record of an offline activity started by the user. It is completed when the user finishes it
class ActivityLogEntry {
  final String id;
  final String activityId;
  final ActivitySource source;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int xp;
  final PartOfDay partOfDay;
  final String? weather;
  final int availableMin;

  const ActivityLogEntry({
    required this.id,
    required this.activityId,
    required this.source,
    required this.startedAt,
    required this.completedAt,
    required this.xp,
    required this.partOfDay,
    required this.weather,
    required this.availableMin,
  });

  ActivityLogEntry complete(DateTime completedAt, int xp) {
    return ActivityLogEntry(
      id: id,
      activityId: activityId,
      source: source,
      startedAt: startedAt,
      completedAt: completedAt,
      xp: xp,
      partOfDay: partOfDay,
      weather: weather,
      availableMin: availableMin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'source': source.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'xp': xp,
      'partOfDay': partOfDay.name,
      'weather': weather,
      'availableMin': availableMin,
    };
  }

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completedAt'] as String?;
    return ActivityLogEntry(
      id: json['id'] as String,
      activityId: json['activityId'] as String,
      source: ActivitySource.values.byName(json['source'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      xp: json['xp'] as int,
      partOfDay: PartOfDay.values.byName(json['partOfDay'] as String),
      weather: json['weather'] as String?,
      availableMin: json['availableMin'] as int,
    );
  }
}

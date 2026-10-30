import 'activity_category.dart';
import 'activity_source.dart';
import 'part_of_day.dart';
import 'place_label.dart';

//Record of an offline activity started by the user. It is completed when the user finishes it
class ActivityLogEntry {
  final String id;
  final String activityId;
  //Null only in logs saved before the category was stored
  final ActivityCategory? category;
  final ActivitySource source;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int xp;
  final PartOfDay partOfDay;
  final String? weather;
  final int availableMin;
  final PlaceLabel? placeLabel;
  //False until the backend has the latest version of the log
  final bool synced;

  const ActivityLogEntry({
    required this.id,
    required this.activityId,
    required this.category,
    required this.source,
    required this.startedAt,
    required this.completedAt,
    required this.xp,
    required this.partOfDay,
    required this.weather,
    required this.availableMin,
    required this.placeLabel,
    this.synced = false,
  });

  //Completing the log changes it, so it has to be synced again
  ActivityLogEntry complete(DateTime completedAt, int xp) {
    return copyWith(completedAt: completedAt, xp: xp, synced: false);
  }

  ActivityLogEntry copyWith({DateTime? completedAt, int? xp, bool? synced}) {
    return ActivityLogEntry(
      id: id,
      activityId: activityId,
      category: category,
      source: source,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      xp: xp ?? this.xp,
      partOfDay: partOfDay,
      weather: weather,
      availableMin: availableMin,
      placeLabel: placeLabel,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityId': activityId,
      'category': category?.name,
      'source': source.name,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'xp': xp,
      'partOfDay': partOfDay.name,
      'weather': weather,
      'availableMin': availableMin,
      'placeLabel': placeLabel?.name,
      'synced': synced,
    };
  }

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completedAt'] as String?;
    final category = json['category'] as String?;
    final placeLabel = json['placeLabel'] as String?;
    return ActivityLogEntry(
      id: json['id'] as String,
      activityId: json['activityId'] as String,
      category: category == null ? null : ActivityCategory.values.byName(category),
      source: ActivitySource.values.byName(json['source'] as String),
      startedAt: DateTime.parse(json['startedAt'] as String),
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      xp: json['xp'] as int,
      partOfDay: PartOfDay.values.byName(json['partOfDay'] as String),
      weather: json['weather'] as String?,
      availableMin: json['availableMin'] as int,
      placeLabel: placeLabel == null ? null : PlaceLabel.values.byName(placeLabel),
      synced: json['synced'] as bool? ?? false,
    );
  }

  //Body expected by the backend (ActivityLog record): epoch milliseconds and enums in uppercase, same as the Kotlin app.
  //The coordinates are not sent: the place is only the label chosen by the user
  Map<String, dynamic> toDto() {
    return {
      'id': id,
      'activityId': activityId,
      'category': category!.name.toUpperCase(),
      'source': source.name.toUpperCase(),
      'interactionId': null,
      'startedAt': startedAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'xp': xp,
      'timeOfDay': partOfDay.name.toUpperCase(),
      'weather': weather?.toUpperCase(),
      'availableMin': availableMin,
      'placeLabel': placeLabel?.name.toUpperCase(),
      'latitude': null,
      'longitude': null,
    };
  }
}

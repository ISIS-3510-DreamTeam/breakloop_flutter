import 'activity_category.dart';
import 'part_of_day.dart';
import 'place_label.dart';
import 'reason_tag.dart';

//What the user did after seeing the suggestions. A pending interaction that is never closed counts as NO_ACTIVITY in the dashboard
enum InteractionOutcome { pending, accepted, otherActivity, noActivity }

//camelCase enum name to the UPPER_SNAKE name used by the backend (otherActivity -> OTHER_ACTIVITY)
String _upperSnake(String name) {
  return name.replaceAllMapped(RegExp('[A-Z]'), (match) => '_${match[0]}').toUpperCase();
}

//Suggestion shown to the user during an interaction
class ShownSuggestion {
  final String activityId;
  final ActivityCategory category;
  final int availableMin;
  final double score;
  final List<ReasonTag> reasons;
  //Milliseconds since epoch
  final int shownAt;

  const ShownSuggestion({
    required this.activityId,
    required this.category,
    required this.availableMin,
    required this.score,
    required this.reasons,
    required this.shownAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'activityId': activityId,
      'category': category.name,
      'availableMin': availableMin,
      'score': score,
      'reasons': [for (final reason in reasons) reason.name],
      'shownAt': shownAt,
    };
  }

  factory ShownSuggestion.fromJson(Map<String, dynamic> json) {
    return ShownSuggestion(
      activityId: json['activityId'] as String,
      category: ActivityCategory.values.byName(json['category'] as String),
      availableMin: json['availableMin'] as int,
      score: (json['score'] as num).toDouble(),
      reasons: [for (final reason in json['reasons'] as List) ReasonTag.values.byName(reason as String)],
      shownAt: json['shownAt'] as int,
    );
  }

  Map<String, dynamic> toDto() {
    return {
      'activityId': activityId,
      'category': category.name.toUpperCase(),
      'availableMin': availableMin,
      'score': score,
      'reasons': [for (final reason in reasons) _upperSnake(reason.name)],
      'shownAt': shownAt,
    };
  }
}

/// One visit to the Offline view: the suggestions shown, the place and what the user chose.
/// It is the data of BQ12, same as SuggestionInteractionEntity in the Kotlin app
class SuggestionInteraction {
  final String id;
  final int openedAt;
  final int? closedAt;
  final PartOfDay partOfDay;
  final bool isWeekend;
  final String? weather;
  final PlaceLabel? placeLabel;
  final List<ShownSuggestion> shownSuggestions;
  final InteractionOutcome outcome;
  //Activity of the suggestions that the user started
  final String? acceptedActivityId;
  //Activity started from the list that was not suggested
  final String? chosenActivityId;
  final int updatedAt;
  //False until the backend has the latest version
  final bool synced;

  const SuggestionInteraction({
    required this.id,
    required this.openedAt,
    required this.closedAt,
    required this.partOfDay,
    required this.isWeekend,
    required this.weather,
    required this.placeLabel,
    required this.shownSuggestions,
    required this.outcome,
    required this.acceptedActivityId,
    required this.chosenActivityId,
    required this.updatedAt,
    this.synced = false,
  });

  SuggestionInteraction copyWith({
    int? closedAt,
    PlaceLabel? placeLabel,
    bool clearPlace = false,
    List<ShownSuggestion>? shownSuggestions,
    InteractionOutcome? outcome,
    String? acceptedActivityId,
    String? chosenActivityId,
    int? updatedAt,
    bool? synced,
  }) {
    return SuggestionInteraction(
      id: id,
      openedAt: openedAt,
      closedAt: closedAt ?? this.closedAt,
      partOfDay: partOfDay,
      isWeekend: isWeekend,
      weather: weather,
      placeLabel: clearPlace ? null : placeLabel ?? this.placeLabel,
      shownSuggestions: shownSuggestions ?? this.shownSuggestions,
      outcome: outcome ?? this.outcome,
      acceptedActivityId: acceptedActivityId ?? this.acceptedActivityId,
      chosenActivityId: chosenActivityId ?? this.chosenActivityId,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'openedAt': openedAt,
      'closedAt': closedAt,
      'partOfDay': partOfDay.name,
      'isWeekend': isWeekend,
      'weather': weather,
      'placeLabel': placeLabel?.name,
      'shownSuggestions': [for (final shown in shownSuggestions) shown.toJson()],
      'outcome': outcome.name,
      'acceptedActivityId': acceptedActivityId,
      'chosenActivityId': chosenActivityId,
      'updatedAt': updatedAt,
      'synced': synced,
    };
  }

  factory SuggestionInteraction.fromJson(Map<String, dynamic> json) {
    final placeLabel = json['placeLabel'] as String?;
    return SuggestionInteraction(
      id: json['id'] as String,
      openedAt: json['openedAt'] as int,
      closedAt: json['closedAt'] as int?,
      partOfDay: PartOfDay.values.byName(json['partOfDay'] as String),
      isWeekend: json['isWeekend'] as bool,
      weather: json['weather'] as String?,
      placeLabel: placeLabel == null ? null : PlaceLabel.values.byName(placeLabel),
      shownSuggestions: [
        for (final shown in json['shownSuggestions'] as List) ShownSuggestion.fromJson(shown as Map<String, dynamic>),
      ],
      outcome: InteractionOutcome.values.byName(json['outcome'] as String),
      acceptedActivityId: json['acceptedActivityId'] as String?,
      chosenActivityId: json['chosenActivityId'] as String?,
      updatedAt: json['updatedAt'] as int,
      synced: json['synced'] as bool? ?? false,
    );
  }

  //Body expected by the backend (SuggestionInteraction record). The coordinates are not sent, only the place label
  Map<String, dynamic> toDto() {
    return {
      'id': id,
      'openedAt': openedAt,
      'closedAt': closedAt,
      'timeOfDay': partOfDay.name.toUpperCase(),
      'isWeekend': isWeekend,
      'weather': weather?.toUpperCase(),
      'placeLabel': placeLabel?.name.toUpperCase(),
      'latitude': null,
      'longitude': null,
      'shownSuggestions': [for (final shown in shownSuggestions) shown.toDto()],
      'outcome': _upperSnake(outcome.name),
      'acceptedActivityId': acceptedActivityId,
      'chosenActivityId': chosenActivityId,
      'declineReason': null,
    };
  }
}

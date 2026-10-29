import 'context_snapshot.dart';
import 'offline_activity.dart';
import 'part_of_day.dart';
import 'recommendation.dart';
import 'rules/scoring_rule.dart';
import 'weather_condition.dart';

//Ranks the catalog for the current context. Each rule gives a score from 0 to 1 that is multiplied by its weight
class RecommendActivityUseCase {
  final List<ScoringRule> rules;

  const RecommendActivityUseCase({required this.rules});

  List<Recommendation> rank(List<OfflineActivity> catalog, ContextSnapshot context) {
    //Activities longer than the available time, and outdoor ones when it rains, snows or it is night, are excluded
    final candidates = catalog.where((activity) {
      final badOutdoorContext = context.weather == WeatherCondition.rain ||
          context.weather == WeatherCondition.snow ||
          context.partOfDay == PartOfDay.night;
      return activity.durationMin <= context.availableMin && !(activity.isOutdoor && badOutdoorContext);
    });

    final recommendations = <Recommendation>[];
    for (final candidate in candidates) {
      final score = rules.fold<double>(0, (sum, rule) {
        return sum + rule.score(candidate, context) * rule.weight;
      });
      //A rule gives a reason only when it fully matches
      final reasons = [
        for (final rule in rules)
          if (rule.score(candidate, context) == 1.0 && rule.reason != null) rule.reason!,
      ];
      recommendations.add(Recommendation(activity: candidate, score: score, reasons: reasons));
    }

    recommendations.sort((a, b) {
      return b.score.compareTo(a.score);
    });
    return recommendations;
  }

  Recommendation? recommend(List<OfflineActivity> catalog, ContextSnapshot context) {
    final ranking = rank(catalog, context);
    if (ranking.isEmpty) {
      return null;
    }
    return ranking.first;
  }
}

import '../context_snapshot.dart';
import '../offline_activity.dart';
import '../reason_tag.dart';
import 'scoring_rule.dart';

class WeatherRule implements ScoringRule {
  @override
  final double weight;
  @override
  final ReasonTag? reason;

  const WeatherRule({this.weight = 0.2, this.reason = ReasonTag.goodWeather});

  @override
  double score(OfflineActivity activity, ContextSnapshot context) {
    if (activity.suitableWeather.contains(context.weather)) {
      return 1.0;
    } else if (context.weather == null) {
      //Neutral score when the weather is unknown
      return 0.5;
    }
    return 0.0;
  }
}

import 'duration_rule.dart';
import 'interest_rule.dart';
import 'part_of_day_rule.dart';
import 'recent_repeat_rule.dart';
import 'scoring_rule.dart';
import 'weather_rule.dart';

class DefaultScoringRules {
  DefaultScoringRules._();

  static const List<ScoringRule> all = [
    DurationRule(),
    PartOfDayRule(),
    WeatherRule(),
    InterestRule(),
    RecentRepeatRule(),
  ];
}

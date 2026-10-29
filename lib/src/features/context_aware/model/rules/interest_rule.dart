import '../context_snapshot.dart';
import '../offline_activity.dart';
import '../reason_tag.dart';
import 'scoring_rule.dart';

class InterestRule implements ScoringRule {
  @override
  final double weight;
  @override
  final ReasonTag? reason;

  const InterestRule({this.weight = 0.35, this.reason = ReasonTag.matchesInterest});

  @override
  double score(OfflineActivity activity, ContextSnapshot context) {
    if (context.interests.contains(activity.category)) {
      return 1.0;
    }
    return 0.5;
  }
}

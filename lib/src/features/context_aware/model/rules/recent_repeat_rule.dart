import '../context_snapshot.dart';
import '../offline_activity.dart';
import '../reason_tag.dart';
import 'scoring_rule.dart';

//Negative weight: penalizes the activities the user completed recently
class RecentRepeatRule implements ScoringRule {
  @override
  final double weight;
  @override
  final ReasonTag? reason;

  const RecentRepeatRule({this.weight = -0.50, this.reason});

  @override
  double score(OfflineActivity activity, ContextSnapshot context) {
    if (context.recentActivityIds.contains(activity.id)) {
      return 1.0;
    }
    return 0.0;
  }
}

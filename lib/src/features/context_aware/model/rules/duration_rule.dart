import '../context_snapshot.dart';
import '../offline_activity.dart';
import '../reason_tag.dart';
import 'scoring_rule.dart';

//Activities that use more of the available time score higher
class DurationRule implements ScoringRule {
  @override
  final double weight;
  @override
  final ReasonTag? reason;

  const DurationRule({this.weight = 0.25, this.reason = ReasonTag.fitsAvailableTime});

  @override
  double score(OfflineActivity activity, ContextSnapshot context) {
    if (activity.durationMin <= context.availableMin) {
      return activity.durationMin / context.availableMin;
    }
    return 0.0;
  }
}

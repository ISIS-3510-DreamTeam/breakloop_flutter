import '../context_snapshot.dart';
import '../offline_activity.dart';
import '../reason_tag.dart';
import 'scoring_rule.dart';

class PartOfDayRule implements ScoringRule {
  @override
  final double weight;
  @override
  final ReasonTag? reason;

  const PartOfDayRule({this.weight = 0.20, this.reason = ReasonTag.rightTimeOfDay});

  @override
  double score(OfflineActivity activity, ContextSnapshot context) {
    if (activity.suitablePartsOfDay.contains(context.partOfDay)) {
      return 1.0;
    }
    return 0.0;
  }
}

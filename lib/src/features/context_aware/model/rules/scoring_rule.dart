import '../context_snapshot.dart';
import '../offline_activity.dart';
import '../reason_tag.dart';

abstract interface class ScoringRule {
  double get weight;

  //Reason shown to the user when this rule fully matches. Null if the rule does not explain the suggestion
  ReasonTag? get reason;

  double score(OfflineActivity activity, ContextSnapshot context);
}

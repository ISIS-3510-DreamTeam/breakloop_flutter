import 'offline_activity.dart';
import 'reason_tag.dart';

class Recommendation {
  final OfflineActivity activity;
  final double score;
  final List<ReasonTag> reasons;

  const Recommendation({
    required this.activity,
    required this.score,
    required this.reasons,
  });
}

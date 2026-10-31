import 'activity_log_entry.dart';
import 'activity_source.dart';

//Screen time avoided by doing suggested activities this week and last week (BQ6)
class AvoidedScreenTime {
  final int thisWeekMs;
  final int lastWeekMs;
  //Suggested activities completed this week
  final int activitiesThisWeek;

  const AvoidedScreenTime({
    required this.thisWeekMs,
    required this.lastWeekMs,
    required this.activitiesThisWeek,
  });
}

//Adds the avoided time of the suggested activities that were completed, grouped by calendar week
//(Sunday to Saturday, the same weeks of the Stats view)
class CalculateAvoidedScreenTimeUseCase {
  const CalculateAvoidedScreenTimeUseCase();

  AvoidedScreenTime calculate(List<ActivityLogEntry> logs, DateTime now) {
    final thisWeekStart = DateTime(now.year, now.month, now.day - now.weekday % 7);
    final lastWeekStart = DateTime(thisWeekStart.year, thisWeekStart.month, thisWeekStart.day - 7);

    var thisWeekMs = 0;
    var lastWeekMs = 0;
    var activitiesThisWeek = 0;
    for (final log in logs) {
      final completedAt = log.completedAt;
      final avoided = log.avoidedScreenMs;
      //Only the suggestions the user accepted and finished
      if (log.source != ActivitySource.recommended || completedAt == null || avoided == null) continue;

      if (!completedAt.isBefore(thisWeekStart)) {
        thisWeekMs += avoided;
        activitiesThisWeek++;
      } else if (!completedAt.isBefore(lastWeekStart)) {
        lastWeekMs += avoided;
      }
    }
    return AvoidedScreenTime(
      thisWeekMs: thisWeekMs,
      lastWeekMs: lastWeekMs,
      activitiesThisWeek: activitiesThisWeek,
    );
  }
}

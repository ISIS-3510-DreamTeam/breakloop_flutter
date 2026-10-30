import '../model/activity_category.dart';
import '../model/activity_log_entry.dart';
import '../model/activity_source.dart';
import '../model/context_snapshot.dart';
import '../model/place_label.dart';

//Log of the offline activities started and completed by the user
abstract interface class ActivityLogRepository {
  //Saves a new log and returns its id
  Future<String> startLog(
    String activityId,
    ActivityCategory category,
    ActivitySource source,
    ContextSnapshot context,
    PlaceLabel? placeLabel,
    String? interactionId,
  );

  //completedAt defaults to now. A timer that ended while the app was closed passes the end of the timer
  Future<void> completeLog(String logId, int xp, {DateTime? completedAt});

  //Latest log of the current account that was started and not completed (of activityId, or of any activity).
  //It lets the timer of an activity continue after leaving the view or closing the app
  Future<ActivityLogEntry?> getOpenLog({String? activityId});

  //Ids of the last completed activities, most recent first
  Future<List<String>> getRecentActivityIds(int limit);

  //Completed logs of the account that is logged in
  Future<List<ActivityLogEntry>> getCompletedLogsOfCurrentUser();

  //Emits every time a log is started or completed
  Stream<void> watchChanges();

  //Sends the logs that the backend does not have yet. If it fails they stay queued for the next try
  Future<void> syncActivityLogs();
}

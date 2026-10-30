import '../model/activity_category.dart';
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
  );

  Future<void> completeLog(String logId, int xp);

  //Ids of the last completed activities, most recent first
  Future<List<String>> getRecentActivityIds(int limit);

  //Sends the logs that the backend does not have yet. If it fails they stay queued for the next try
  Future<void> syncActivityLogs();
}

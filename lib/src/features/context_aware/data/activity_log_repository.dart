import '../model/activity_source.dart';
import '../model/context_snapshot.dart';

//Log of the offline activities started and completed by the user
abstract interface class ActivityLogRepository {
  //Saves a new log and returns its id
  Future<String> startLog(String activityId, ActivitySource source, ContextSnapshot context);

  Future<void> completeLog(String logId, int xp);

  //Ids of the last completed activities, most recent first
  Future<List<String>> getRecentActivityIds(int limit);
}

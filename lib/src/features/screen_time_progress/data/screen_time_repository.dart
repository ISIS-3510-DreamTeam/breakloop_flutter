import '../model/daily_screen_time.dart';

//Source of the user's daily screen-time records.
abstract interface class ScreenTimeRepository {
  //Whether the source can be read right now
  Future<bool> hasPermission();

  //Ask the user for the permission needed to read the source
  Future<void> requestPermission();

  //Get the daily records of the user.
  Future<List<DailyScreenTime>> getDailyScreenTime();
}

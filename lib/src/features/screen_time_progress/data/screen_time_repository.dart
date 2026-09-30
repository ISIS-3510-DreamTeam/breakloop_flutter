import '../model/daily_screen_time.dart';

//Source of the user's daily screen-time records.
//The ViewModel only depends on this interface, so the mock can later be replaced by a real source without changing it.
abstract interface class ScreenTimeRepository {
  //Get the daily records of the user.
  Future<List<DailyScreenTime>> getDailyScreenTime();
}

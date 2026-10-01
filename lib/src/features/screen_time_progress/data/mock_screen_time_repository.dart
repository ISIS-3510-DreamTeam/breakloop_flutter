import '../model/daily_screen_time.dart';
import 'screen_time_repository.dart';

//MOCK DATA: simulated screen-time records used until the app has a real data source.
//TODO: Replace with a real implementation (usage tracking / Firestore sync) once it is available.
class MockScreenTimeRepository implements ScreenTimeRepository {
  //4 calendar weeks (Sunday to Saturday) of deterministic minutes with a downward trend.
  static const List<int> _dailyMinutes = [
  415, 342, 329, 351, 338, 374, 431, // Week 1 (baseline)
  392, 327, 316, 339, 321, 352, 388, // Week 2
  401, 338, 325, 352, 336, 361, 398, // Week 3
  338, 268, 259, 281, 264, 289, 351, // Week 4
];

  //The mock data needs no permission
  @override
  Future<bool> hasPermission() async {
    return true;
  }

  @override
  Future<void> requestPermission() async {}

  @override
  Future<List<DailyScreenTime>> getDailyScreenTime() async {
    final now = DateTime.now();
    //DateTime.weekday goes from Monday (1) to Sunday (7), so % 7 gives the days elapsed since Sunday
    final daysSinceSunday = now.weekday % 7;

    //The data starts on the Sunday 3 weeks before the current one and ends today,
    //so the current week only has the days from Sunday up to today
    return [
      for (var i = 0; i <= 21 + daysSinceSunday; i++)
        DailyScreenTime(
          date: DateTime(now.year, now.month, now.day - daysSinceSunday - 21 + i),
          minutes: _dailyMinutes[i],
        ),
    ];
  }

}

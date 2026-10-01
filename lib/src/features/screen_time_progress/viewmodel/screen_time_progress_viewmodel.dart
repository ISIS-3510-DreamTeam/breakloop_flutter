import 'package:flutter/foundation.dart';
import '../data/screen_time_repository.dart';
import '../model/daily_screen_time.dart';
import '../model/weekly_screen_time.dart';

enum ScreenTimeProgressStatus { idle, loading, permissionRequired, loaded, error }

class ScreenTimeProgressViewModel extends ChangeNotifier {
  final ScreenTimeRepository _repository;
  ScreenTimeProgressViewModel(this._repository);

  ScreenTimeProgressStatus status = ScreenTimeProgressStatus.idle;

  //Average daily screen time of each week of use, oldest first
  List<WeeklyScreenTime> weeks = [];

  //Reduction of the current week against the baseline, in %. A negative value means usage increased.
  //It is null when there is no data yet or the baseline is zero, so the view can show a neutral state.
  double? reductionPercent;

  //The baseline is fixed: it is always the first calendar week of use (it may be a partial week)
  WeeklyScreenTime? get baselineWeek {
    if (weeks.isEmpty) {
      return null;
    } else {
      return weeks.first;
    }
  }

  //The current week is the most recent calendar week with data (it may be a partial week)
  WeeklyScreenTime? get currentWeek {
    if (weeks.isEmpty) {
      return null;
    } else {
      return weeks.last;
    }
  }

  Future<void> load() async {
    status = ScreenTimeProgressStatus.loading;
    notifyListeners();

    try {
      if (!await _repository.hasPermission()) {
        status = ScreenTimeProgressStatus.permissionRequired;
        notifyListeners();
        return;
      }

      final records = await _repository.getDailyScreenTime();
      weeks = _groupByWeek(records);
      reductionPercent = _computeReduction();
      status = ScreenTimeProgressStatus.loaded;

    } catch (_) {
      status = ScreenTimeProgressStatus.error;
    }
    notifyListeners();
  }

  //Send the user to grant the permission. The view calls load() again when the user comes back to the app.
  Future<void> requestPermission() async {
    await _repository.requestPermission();
  }

  //Split the records into calendar weeks (Sunday to Saturday), counted from the week of the first day of use.
  //Each week is averaged over the days that have data, so a partial week still works.
  List<WeeklyScreenTime> _groupByWeek(List<DailyScreenTime> records) {
    if (records.isEmpty) {
      return [];
    }

    final sorted = [...records]..sort((a, b) {
      return a.date.compareTo(b.date);
    });
    final firstSunday = _sundayOf(sorted.first.date);

    //Week index -> minutes of each day of that week, from Sunday to Saturday
    final daysByWeek = <int, List<int?>>{};
    for (final record in sorted) {
      final daysSinceFirstSunday = _dayOnly(record.date).difference(firstSunday).inDays;
      final week = daysByWeek.putIfAbsent(daysSinceFirstSunday ~/ 7, () {
        return List.filled(7, null);
      });
      week[daysSinceFirstSunday % 7] = record.minutes;
    }

    //The records are sorted, so the weeks are already in chronological order
    return [
      for (final entry in daysByWeek.entries)
        WeeklyScreenTime(
          weekNumber: entry.key + 1,
          averageDailyMinutes: _averageOfDaysWithData(entry.value),
          dailyMinutes: entry.value,
        ),
    ];
  }

  //Every week in the list has at least one day with data, so there is no division by zero
  double _averageOfDaysWithData(List<int?> dailyMinutes) {
    final minutes = dailyMinutes.whereType<int>();
    return minutes.reduce((a, b) {
      return a + b;
    }) / minutes.length;
  }

  //Reduction % = (baseline - current) / baseline * 100
  double? _computeReduction() {
    final baseline = baselineWeek?.averageDailyMinutes ?? 0;
    final current = currentWeek?.averageDailyMinutes ?? 0;
    if (baseline == 0) {
      return null;
    }
    return (baseline - current) / baseline * 100;
  }

  //We keep only the date in UTC, so the day difference is not affected by daylight saving changes
  DateTime _dayOnly(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  //Sunday that starts the week of the given date. DateTime.weekday goes from Monday (1) to Sunday (7),
  //so % 7 gives the days elapsed since Sunday
  DateTime _sundayOf(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day - date.weekday % 7);
  }

}

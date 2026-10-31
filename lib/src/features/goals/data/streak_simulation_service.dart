import 'dart:isolate';
import 'package:breakloop_flutter/src/features/screen_time_progress/model/daily_screen_time.dart';

import '../model/streak_simulation_input.dart';
import '../model/streak_simulation_result.dart';
import 'streak_simulator.dart';

class StreakSimulationService {

    const StreakSimulationService();

    Future<StreakSimulationResult> simulate( List<DailyScreenTime> records, {DateTime? now}) {
      final today = _dateOnly(now ?? DateTime.now());
      final tomorrow = DateTime(today.year, today.month, today.day + 1);

      final past = records.where ((r)=> _dateOnly(r.date).isBefore(today)).toList();

      final input = StreakSimulationInput(
          minutes: [for (final r in past ) r.minutes],
          weekdays: [for (final r in past ) r.date.weekday],
          startWeekday: tomorrow.weekday,
      );

      return _runInIsolate(input);
    }

    static Future<StreakSimulationResult> _runInIsolate(StreakSimulationInput input) {
      return Isolate.run(() => runStreakSimulation(input));
    }

    static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
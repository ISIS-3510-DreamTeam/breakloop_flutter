import 'package:breakloop_flutter/src/features/screen_time_progress/model/daily_screen_time.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../data/goals_repository.dart';
import '../model/goal_model.dart';
import '../model/daily_progress.dart';

import 'package:breakloop_flutter/src/features/screen_time_progress/data/screen_time_repository.dart';

enum GoalsStatus {
  loading,
  needsSetup,
  permissionRequired,
  active,
  error
}

class GoalsViewModel extends ChangeNotifier {
  final GoalsRepository _goalsRepository;
  final ScreenTimeRepository _screenTimeRepository;
  Timer? _refreshTimer;

  GoalsViewModel(this._goalsRepository, this._screenTimeRepository){
    _subscribeToGoal();
    //We added a timer to refresh data every minute.
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_)=>reloadUsage());
  }

  GoalsStatus status =  GoalsStatus.loading;
  GoalModel goal = const GoalModel();
  DailyProgress? progress;

  void _subscribeToGoal() {
    _goalsRepository.watchGoal().listen((updatedGoal) async {
      goal = updatedGoal;

      if (!updatedGoal.isConfigured) {
        status = GoalsStatus.needsSetup;
        notifyListeners();
        return;
      }

      await _handleDayRolloverIfNeeded(updatedGoal);
      await _loadTodayUsage(updatedGoal.dailyLimitMinutes!);

    });
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> _handleDayRolloverIfNeeded(GoalModel currentGoal) async {
    //this function only does something when it is a new day. For instance, at midnight.

    final today = _dateOnly(DateTime.now());
    final lastEval = currentGoal.lastEvaluationDate;
    //We check if it is a new day
    final isNewDay = lastEval==null || _dateOnly(lastEval) != today;

    //If it is not a new day we do nothing.
    if (!isNewDay) return;
    
    int newStreak = currentGoal.currentStreak;

    //if the streak has already started we update to the new value.
    if (lastEval != null){
      newStreak = currentGoal.streakBrokenToday ? 0 : currentGoal.currentStreak + 1;
    }

    //if there is a new goal we set it up
    if (currentGoal.pendingDailyLimitMinutes != null) {
      await _goalsRepository.applyPendingLimitAndClear(currentGoal.pendingDailyLimitMinutes!);
    }

    await _goalsRepository.updateStreak(
        newStreak: newStreak,
        lastEvaluationDate: today,
        //since we are starting a new day, the streak has not been broken yet.
        streakBrokenToday: false,
    );
  }

  Future<void> _loadTodayUsage(int goalMinutes) async {
    try {
      if (!await _screenTimeRepository.hasPermission()) {
        status = GoalsStatus.permissionRequired;
        notifyListeners();
        return;
      }

      final records = await _screenTimeRepository.getDailyScreenTime();
      final usedToday = _findToday(records)?.minutes ?? 0;

      progress = DailyProgress(usedMinutes: usedToday, goalMinutes: goalMinutes);
      status = GoalsStatus.active;

      //We check if the current time-screen violates the current objective, if it does we reset the streak. We only perform the change once.
      if (progress!.isOverGoal && !goal.streakBrokenToday) {
        await _goalsRepository.updateStreak(
            newStreak: 0,
            lastEvaluationDate: goal.lastEvaluationDate ?? _dateOnly(DateTime.now()),
            streakBrokenToday: true,
        );
      }

    } catch (_) {
      status = GoalsStatus.error;
    }
    notifyListeners();
  }

  DailyScreenTime? _findToday(List<DailyScreenTime> records) {
    final now = DateTime.now();
    for (final record in records) {
      if (record.date.year == now.year && record.date.month == now.month &&  record.date.day == now.day) {
        return record;
      }
    }
    return null;
  }

  //In case permission has not been granted yet we also offer this function in this viewmodel.
  Future<void> requestPermission() => _screenTimeRepository.requestPermission();

  Future<void> reloadUsage() async {
    if (goal.isConfigured) await _loadTodayUsage(goal.dailyLimitMinutes!);
  }

  Future<void> setDailyLimit(int minutes) => _goalsRepository.setDailyLimit(minutes);

  Future<void> scheduleNewLimit(int minutes) => _goalsRepository.schedulePendingLimit(minutes);

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _goalsRepository.dispose();
    super.dispose();
  }


}
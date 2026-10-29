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
  bool _isProcessingRollover = false;
  //identifier to prevent race-conditions
  int _usageRequestId = 0;

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

      debugPrint('[GoalsViewModel] stream emitted → '
          'dailyLimit=${updatedGoal.dailyLimitMinutes}, '
          'pending=${updatedGoal.pendingDailyLimitMinutes}, '
          'streak=${updatedGoal.currentStreak}, '
          'lastEval=${updatedGoal.lastEvaluationDate}, '
          'broken=${updatedGoal.streakBrokenToday}');

      goal = updatedGoal;

      if (!updatedGoal.isConfigured) {
        status = GoalsStatus.needsSetup;
        notifyListeners();
        return;
      }

      await _refreshGoalState();

    });
  }

  Future<void> _refreshGoalState() async {
    await _handleDayRolloverIfNeeded(goal);
    await _loadTodayUsage(goal.dailyLimitMinutes!);
  }

  Future<void> reloadUsage() async {
    if (goal.isConfigured) await _refreshGoalState();
  }

  Future<void> _handleDayRolloverIfNeeded(GoalModel currentGoal) async {
    //To prevent re-entries when a similar process is already running.
    if (_isProcessingRollover) return;
    final today = _dateOnly(DateTime.now());
    final lastEval = currentGoal.lastEvaluationDate;
    final isNewDay = lastEval == null || _dateOnly(lastEval) != today;

    if (!isNewDay) return;

    _isProcessingRollover = true;
    try {
      int newStreak = currentGoal.currentStreak;
      if (lastEval != null) {
        newStreak = currentGoal.streakBrokenToday ? 0 : currentGoal.currentStreak + 1;
      }

      await _goalsRepository.applyDayRollover(
        newDailyLimitMinutes: currentGoal.pendingDailyLimitMinutes,
        currentStreak: newStreak,
        lastEvaluationDate: today,
      );
    } finally {
      _isProcessingRollover = false;
    }
  }

  Future<void> _loadTodayUsage(int goalMinutes) async {
    final requestId = ++_usageRequestId;
    try {
      if (!await _screenTimeRepository.hasPermission()) {
        status = GoalsStatus.permissionRequired;
        notifyListeners();
        return;
      }

      final records = await _screenTimeRepository.getDailyScreenTime();

      // A recent petition is already running, so we ignore this call to prevent overwriting.
      if (requestId != _usageRequestId) {
        debugPrint('[GoalsViewModel] discarding stale usage result (requestId=$requestId, current=$_usageRequestId)');
        return;
      }

      final usedToday = _findToday(records)?.minutes ?? 0;

      progress = DailyProgress(usedMinutes: usedToday, goalMinutes: goalMinutes);
      status = GoalsStatus.active;

      debugPrint('[GoalsViewModel] usage loaded → used=$usedToday, goal=$goalMinutes, '
          'isOverGoal=${progress!.isOverGoal}, alreadyBroken=${goal.streakBrokenToday}');

      //We check if the current time-screen violates the current objective, if it does we reset the streak. We only perform the change once.
      if (progress!.isOverGoal && !goal.streakBrokenToday) {
        debugPrint('[GoalsViewModel] BREAKING STREAK NOW (over goal, not yet marked)');
        await _goalsRepository.updateStreak(
          newStreak: 0,
          lastEvaluationDate: goal.lastEvaluationDate ?? _dateOnly(DateTime.now()),
          streakBrokenToday: true,
        );
      }

    } catch (e) {
      if (requestId != _usageRequestId) return;
      debugPrint('[GoalsViewModel] ERROR loading usage: $e');
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

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  //In case permission has not been granted yet we also offer this function in this viewmodel.
  Future<void> requestPermission() => _screenTimeRepository.requestPermission();

  Future<void> setDailyLimit(int minutes) => _goalsRepository.setDailyLimit(minutes);

  Future<void> scheduleNewLimit(int minutes) {
    debugPrint('[GoalsViewModel] scheduleNewLimit($minutes) called');
    return _goalsRepository.schedulePendingLimit(minutes);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _goalsRepository.dispose();
    super.dispose();
  }
}
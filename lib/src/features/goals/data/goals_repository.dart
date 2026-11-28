import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/goal_model.dart';

class GoalsRepository {
  final _goalController = StreamController<GoalModel>.broadcast();

  GoalsRepository() {
    _loadInitialGoal();
  }

  Future<void> _loadInitialGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt('dailyLimitMinutes');
    final pendingMinutes = prefs.getInt('pendingDailyLimitMinutes');
    final streak = prefs.getInt('currentStreak') ?? 0;
    final longest = prefs.getInt('longestStreak') ?? 0;
    final lastEvaluationDateStr = prefs.getString('lastEvaluationDate');
    final streakBrokenTodayBool = prefs.getBool('streakBrokenToday');

    debugPrint('[GoalsRepository] _loadInitialGoal → '
        'dailyLimit=$minutes, pending=$pendingMinutes, streak=$streak, '
        'longest=$longest, lastEval=$lastEvaluationDateStr, broken=$streakBrokenTodayBool');

    _goalController.add(GoalModel(
      dailyLimitMinutes: minutes,
      pendingDailyLimitMinutes: pendingMinutes,
      currentStreak: streak,
      longestStreak: longest,
      lastEvaluationDate: lastEvaluationDateStr != null ? DateTime.parse(lastEvaluationDateStr) : null,
      streakBrokenToday: streakBrokenTodayBool ?? false,
    ));
  }

  Future<GoalModel> getCurrentGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final lastEvaluation = prefs.getString('lastEvaluationDate');
    return GoalModel(
      dailyLimitMinutes: prefs.getInt('dailyLimitMinutes'),
      pendingDailyLimitMinutes: prefs.getInt('pendingDailyLimitMinutes'),
      currentStreak: prefs.getInt('currentStreak') ?? 0,
      longestStreak: prefs.getInt('longestStreak') ?? 0,
      lastEvaluationDate:
      lastEvaluation != null ? DateTime.parse(lastEvaluation) : null,
      streakBrokenToday: prefs.getBool('streakBrokenToday') ?? false,
    );
  }

  Stream<GoalModel> watchGoal() => _goalController.stream;

  Future<void> setDailyLimit(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyLimitMinutes', minutes);
    //Emits the updated state
    await _loadInitialGoal();
  }

  Future<void> schedulePendingLimit(int minutes) async {
    debugPrint('[GoalsRepository] schedulePendingLimit($minutes) called');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pendingDailyLimitMinutes', minutes);
    await _loadInitialGoal();
  }

  Future<void> applyPendingLimitAndClear(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyLimitMinutes', minutes);
    await prefs.remove('pendingDailyLimitMinutes');
    await _loadInitialGoal();
  }

  Future<void> updateStreak({
    required int newStreak,
    required DateTime lastEvaluationDate,
    required bool streakBrokenToday,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentStreak', newStreak);
    await prefs.setString('lastEvaluationDate', lastEvaluationDate.toIso8601String());
    await prefs.setBool('streakBrokenToday', streakBrokenToday);
    await _keepLongest(prefs, newStreak);
    // Any local change to the streak must reach the cloud, whoever made it.
    // Set before emitting, so the listener already sees the flag.
    await prefs.setBool('streakPendingSync', true);
    await _loadInitialGoal();
  }

  Future<void> applyDayRollover({
    required int? newDailyLimitMinutes,
    required int currentStreak,
    required DateTime lastEvaluationDate,
  }) async {
    debugPrint('[GoalsRepository] applyDayRollover → '
        'newLimit=$newDailyLimitMinutes, streak=$currentStreak, date=$lastEvaluationDate');
    final prefs = await SharedPreferences.getInstance();
    if (newDailyLimitMinutes != null) {
      await prefs.setInt('dailyLimitMinutes', newDailyLimitMinutes);
      await prefs.remove('pendingDailyLimitMinutes');
    }
    await prefs.setInt('currentStreak', currentStreak);
    await prefs.setString('lastEvaluationDate', lastEvaluationDate.toIso8601String());
    await prefs.setBool('streakBrokenToday', false);
    await _keepLongest(prefs, currentStreak);
    await prefs.setBool('streakPendingSync', true);
    await _loadInitialGoal();
  }

  // Sets the streak values that come from the cloud. Only used on a device
  // without local history, so the day rollover keeps the restored streak.
  Future<void> restoreStreak({required int streak, required int longestStreak}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentStreak', streak);
    await prefs.setInt('longestStreak', longestStreak);
    await _loadInitialGoal();
  }

  // True when the streak has changed and the backend does not have it yet.
  Future<bool> isStreakPendingSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('streakPendingSync') ?? false;
  }

  Future<void> setStreakPendingSync(bool pending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('streakPendingSync', pending);
  }

  // The longest streak only goes up.
  Future<void> _keepLongest(SharedPreferences prefs, int streak) async {
    final stored = prefs.getInt('longestStreak') ?? 0;
    if (streak > stored) {
      await prefs.setInt('longestStreak', streak);
    }
  }

  void dispose() => _goalController.close();
}
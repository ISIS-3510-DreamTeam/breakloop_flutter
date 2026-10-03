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
    final lastEvaluationDateStr = prefs.getString('lastEvaluationDate');
    final streakBrokenTodayBool = prefs.getBool('streakBrokenToday');

    debugPrint('[GoalsRepository] _loadInitialGoal → '
        'dailyLimit=$minutes, pending=$pendingMinutes, streak=$streak, '
        'lastEval=$lastEvaluationDateStr, broken=$streakBrokenTodayBool');

    _goalController.add(GoalModel(
      dailyLimitMinutes: minutes,
      pendingDailyLimitMinutes: pendingMinutes,
      currentStreak: streak,
      lastEvaluationDate: lastEvaluationDateStr != null ? DateTime.parse(lastEvaluationDateStr) : null,
      streakBrokenToday: streakBrokenTodayBool ?? false,
    ));
  }

  Stream<GoalModel> watchGoal() =>_goalController.stream;

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



  Future<void> updateStreak({required int newStreak, required DateTime lastEvaluationDate, required bool streakBrokenToday}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentStreak', newStreak);
    await prefs.setString('lastEvaluationDate', lastEvaluationDate.toIso8601String());
    await prefs.setBool('streakBrokenToday',streakBrokenToday);
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
    await _loadInitialGoal();
  }

  void dispose() => _goalController.close();


}
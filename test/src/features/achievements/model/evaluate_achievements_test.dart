import 'package:flutter_test/flutter_test.dart';
import 'package:breakloop_flutter/src/features/achievements/model/achievement.dart';
import 'package:breakloop_flutter/src/features/achievements/model/evaluate_achievements.dart';
import 'package:breakloop_flutter/src/features/achievements/model/evaluation_input.dart';

Achievement _ach(String id, AchievementRule rule, int target) => Achievement(
  id: id,
  name: id,
  description: '',
  image: 'achievements/$id.png',
  rule: rule,
  target: target,
);

final _start = DateTime.utc(2026, 11, 1);

DayUsage _day(int offset, int minutes) =>
    DayUsage(date: _start.add(Duration(days: offset)), minutes: minutes);

void main() {
  test('streak unlocks at the target, not before', () {
    final catalog = [_ach('streak_7', AchievementRule.streakDays, 7)];

    final at6 = evaluateAchievements(
      catalog,
      EvaluationInput(days: [], dailyLimitMinutes: 100, streak: 6, completedFocusSessions: 0),
    );
    final at7 = evaluateAchievements(
      catalog,
      EvaluationInput(days: [], dailyLimitMinutes: 100, streak: 7, completedFocusSessions: 0),
    );

    expect(at6.single.unlocked, false);
    expect(at7.single.unlocked, true);
  });

  test('first day under limit: 99 min unlocks, 100 min does not', () {
    final catalog = [_ach('first', AchievementRule.firstDayUnderLimit, 1)];

    final under = evaluateAchievements(
      catalog,
      EvaluationInput(days: [_day(0, 99)], dailyLimitMinutes: 100, streak: 0, completedFocusSessions: 0),
    );
    final atLimit = evaluateAchievements(
      catalog,
      EvaluationInput(days: [_day(0, 100)], dailyLimitMinutes: 100, streak: 0, completedFocusSessions: 0),
    );

    expect(under.single.unlocked, true);
    expect(atLimit.single.unlocked, false);
  });

  test('80% boundary: 79% counts as under, exactly 80% does not', () {
    final catalog = [_ach('week', AchievementRule.daysUnder80InARow, 7)];

    final days79 = [for (var i = 0; i < 7; i++) _day(i, 79)];
    final days80 = [for (var i = 0; i < 7; i++) _day(i, 80)];

    final under = evaluateAchievements(
      catalog,
      EvaluationInput(days: days79, dailyLimitMinutes: 100, streak: 0, completedFocusSessions: 0),
    );
    final atEighty = evaluateAchievements(
      catalog,
      EvaluationInput(days: days80, dailyLimitMinutes: 100, streak: 0, completedFocusSessions: 0),
    );

    expect(under.single.unlocked, true);
    expect(atEighty.single.current, 0);
  });

  test('non-consecutive days do not add up', () {
    final catalog = [_ach('week', AchievementRule.daysUnder80InARow, 7)];

    // Days 0-2 and 4-7 under the limit, with day 3 missing: longest run is 4
    final days = [_day(0, 10), _day(1, 10), _day(2, 10), _day(4, 10), _day(5, 10), _day(6, 10), _day(7, 10)];

    final result = evaluateAchievements(
      catalog,
      EvaluationInput(days: days, dailyLimitMinutes: 100, streak: 0, completedFocusSessions: 0),
    );

    expect(result.single.current, 4);
    expect(result.single.unlocked, false);
  });

  test('without a daily limit, rules based on the limit do not unlock', () {
    final catalog = [
      _ach('first', AchievementRule.firstDayUnderLimit, 1),
      _ach('week', AchievementRule.daysUnder80InARow, 7),
    ];

    final result = evaluateAchievements(
      catalog,
      EvaluationInput(days: [for (var i = 0; i < 7; i++) _day(i, 0)], dailyLimitMinutes: null, streak: 0, completedFocusSessions: 0),
    );

    expect(result.every((p) => !p.unlocked), true);
  });
}
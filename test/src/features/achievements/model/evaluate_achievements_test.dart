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

EvaluationInput _input({
  List<DayUsage> days = const [],
  int? limit = 100,
  int streak = 0,
  int focus = 0,
}) =>
    EvaluationInput(
      days: days,
      dailyLimitMinutes: limit,
      streak: streak,
      completedFocusSessions: focus,
    );

void main() {
  test('first day unlocks when the streak reaches 1, not before', () {
    final catalog = [_ach('first', AchievementRule.firstDayUnderLimit, 1)];

    final at0 = evaluateAchievements(catalog, _input(streak: 0));
    final at1 = evaluateAchievements(catalog, _input(streak: 1));

    expect(at0.single.unlocked, false);
    expect(at1.single.unlocked, true);
  });

  test('first day ignores usage data, so a partial today does not unlock it', () {
    final catalog = [_ach('first', AchievementRule.firstDayUnderLimit, 1)];

    final result = evaluateAchievements(
      catalog,
      _input(days: [_day(0, 10)], streak: 0),
    );

    expect(result.single.unlocked, false);
  });

  test('streak unlocks at the target, not before', () {
    final catalog = [_ach('streak_7', AchievementRule.streakDays, 7)];

    final at6 = evaluateAchievements(catalog, _input(streak: 6));
    final at7 = evaluateAchievements(catalog, _input(streak: 7));

    expect(at6.single.unlocked, false);
    expect(at7.single.unlocked, true);
  });

  test('80% boundary: 79% counts as under, exactly 80% does not', () {
    final catalog = [_ach('week', AchievementRule.daysUnder80InARow, 7)];

    final days79 = [for (var i = 0; i < 7; i++) _day(i, 79)];
    final days80 = [for (var i = 0; i < 7; i++) _day(i, 80)];

    final under = evaluateAchievements(catalog, _input(days: days79));
    final atEighty = evaluateAchievements(catalog, _input(days: days80));

    expect(under.single.unlocked, true);
    expect(atEighty.single.current, 0);
  });

  test('non-consecutive days do not add up', () {
    final catalog = [_ach('week', AchievementRule.daysUnder80InARow, 7)];

    // Days 0-2 and 4-7 under the limit, with day 3 missing: longest run is 4
    final days = [
      _day(0, 10), _day(1, 10), _day(2, 10),
      _day(4, 10), _day(5, 10), _day(6, 10), _day(7, 10),
    ];

    final result = evaluateAchievements(catalog, _input(days: days));

    expect(result.single.current, 4);
    expect(result.single.unlocked, false);
  });

  test('without a daily limit, limit-based rules do not unlock', () {
    final catalog = [
      _ach('first', AchievementRule.firstDayUnderLimit, 1),
      _ach('week', AchievementRule.daysUnder80InARow, 7),
    ];

    final result = evaluateAchievements(
      catalog,
      _input(days: [for (var i = 0; i < 7; i++) _day(i, 0)], limit: null, streak: 0),
    );

    expect(result.every((p) => !p.unlocked), true);
  });

  test('focus constant unlocks at 10 completed sessions', () {
    final catalog = [_ach('focus', AchievementRule.focusSessionsCompleted, 10)];

    final at9 = evaluateAchievements(catalog, _input(focus: 9));
    final at10 = evaluateAchievements(catalog, _input(focus: 10));

    expect(at9.single.unlocked, false);
    expect(at10.single.unlocked, true);
  });
}
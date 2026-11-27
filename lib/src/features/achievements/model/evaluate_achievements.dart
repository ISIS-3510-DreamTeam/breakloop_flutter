import 'achievement.dart';
import 'achievement_progress.dart';
import 'evaluation_input.dart';

List<AchievementProgress> evaluateAchievements(
    List<Achievement> catalog,
    EvaluationInput input,
    ){
  return catalog.map((achievement) {
    final current = _currentFor(achievement, input);
    return AchievementProgress(
      achievement: achievement,
      current: current,
      unlocked: current >= achievement.target,
    );
  }).toList();
}

int _currentFor(Achievement achievement, EvaluationInput input) {
  switch (achievement.rule) {
    case AchievementRule.firstDayUnderLimit:
      return input.streak >= 1 ? 1 : 0;

    case AchievementRule.streakDays:
      return input.streak;

    case AchievementRule.focusSessionsCompleted:
      return input.completedFocusSessions;

    case AchievementRule.daysUnder80InARow:
      return _longestRunUnder80(input);
  }
}

//Longest run of consec utive days with less than 80% of limit used
int _longestRunUnder80(EvaluationInput input) {
  final limit = input.dailyLimitMinutes;
  if(limit == null || limit <= 0 ) return 0;

  final days = [...input.days]..sort((a,b) => a.date.compareTo(b.date));

  int best = 0;
  int run = 0;
  DateTime? previous;

  for(final day in days) {
    final date = DateTime.utc(day.date.year, day.date.month, day.date.day);
    final consecutive = previous != null && date.difference(previous).inDays ==1;
    final under = day.minutes * 5 < limit * 4;

    run = under ? (consecutive ? run + 1: 1) : 0;
    if (run > best) best = run;
    previous = date;
  }
  return best;
}
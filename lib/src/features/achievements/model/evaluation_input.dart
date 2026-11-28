
class DayUsage {
  final DateTime date;
  final int minutes;

  const DayUsage({required this.date, required this.minutes});
}

class EvaluationInput {
  final List<DayUsage> days;
  final int? dailyLimitMinutes;
  final int streak;
  final int completedFocusSessions;

  const EvaluationInput({
    required this.days,
    required this.dailyLimitMinutes,
    required this.streak,
    required this.completedFocusSessions
  });

}
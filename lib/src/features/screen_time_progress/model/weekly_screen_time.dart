class WeeklyScreenTime {
  final int weekNumber;
  final double averageDailyMinutes;
  //Minutes of each day from Sunday to Saturday. A day without data is null.
  final List<int?> dailyMinutes;

  const WeeklyScreenTime({
    required this.weekNumber,
    required this.averageDailyMinutes,
    required this.dailyMinutes,
  });

  String get label {
    return 'Week $weekNumber';
  }

}

class DailyProgress {
  final int usedMinutes;
  final int goalMinutes;

  const DailyProgress({required this.usedMinutes, required this.goalMinutes});
  int get remainingMinutes => (goalMinutes - usedMinutes).clamp(0, goalMinutes);
  double get fractionUsed => goalMinutes == 0 ? 0 : (usedMinutes/goalMinutes).clamp(0,1.5);
  bool get isOverGoal => usedMinutes > goalMinutes;
  bool get hasReachedThreshold80 => fractionUsed >= 0.8;
}
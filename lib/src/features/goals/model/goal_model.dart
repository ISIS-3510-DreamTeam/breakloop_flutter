class GoalModel {
  // if this variable is null, then the user has not selected a limit yet
  final int? dailyLimitMinutes;
  // If the user changes their objective, the change becomes valid on the next day
  final int? pendingDailyLimitMinutes;

  final int currentStreak;
  final DateTime? lastEvaluationDate;

  //Bool for checking if the streak was broken today
  final bool streakBrokenToday;


  const GoalModel({
    this.dailyLimitMinutes,
    this.pendingDailyLimitMinutes,
    this.currentStreak = 0,
    this.lastEvaluationDate,
    this.streakBrokenToday = false,
  });

  bool get isConfigured => dailyLimitMinutes != null;

  factory GoalModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GoalModel();
    return GoalModel(
      dailyLimitMinutes: data['dailyLimitMinutes'] as int?,
      pendingDailyLimitMinutes: data['pendingDailyLimitMinutes'] as int?,
      currentStreak: data['currentStreak'] as int? ?? 0,
      lastEvaluationDate: data['lastEvaluationDate'] != null
        ? DateTime.parse(data['lastStreakUpdate'] as String)
        : null,
      streakBrokenToday: data['streakBrokenToday'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'dailyLimitMinutes': dailyLimitMinutes,
    'pendingDailyLimitMinutes': pendingDailyLimitMinutes,
    'currentStreak': currentStreak,
    'lastStreakUpdate': lastEvaluationDate?.toIso8601String(),
    'streakBrokenToday': streakBrokenToday,
  };
}


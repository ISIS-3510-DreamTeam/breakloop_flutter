class GoalModel {
  // if this variable is null, then the user has not selected a limit yet
  final int? dailyLimitMinutes;
  // If the user changes their objective, the change becomes valid on the next day
  final int? pendingDailyLimitMinutes;

  final int currentStreak;
  final int longestStreak;
  final DateTime? lastEvaluationDate;

  //Bool for checking if the streak was broken today
  final bool streakBrokenToday;


  const GoalModel({
    this.dailyLimitMinutes,
    this.pendingDailyLimitMinutes,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastEvaluationDate,
    this.streakBrokenToday = false,
  });

  bool get isConfigured => dailyLimitMinutes != null;

  factory GoalModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const GoalModel();

    final lastEvaluation = data['lastEvaluationDate'] as String?;

    return GoalModel(
      dailyLimitMinutes: data['dailyLimitMinutes'] as int?,
      pendingDailyLimitMinutes: data['pendingDailyLimitMinutes'] as int?,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      lastEvaluationDate: lastEvaluation != null ? DateTime.parse(lastEvaluation) : null,
      streakBrokenToday: data['streakBrokenToday'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'dailyLimitMinutes': dailyLimitMinutes,
    'pendingDailyLimitMinutes': pendingDailyLimitMinutes,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastEvaluationDate': lastEvaluationDate?.toIso8601String(),
    'streakBrokenToday': streakBrokenToday,
  };
}


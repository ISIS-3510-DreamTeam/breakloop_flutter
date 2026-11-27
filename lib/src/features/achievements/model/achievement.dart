
enum AchievementRule {
  firstDayUnderLimit,
  streakDays,
  focusSessionsCompleted,
  daysUnder80InARow,
}

AchievementRule _ruleFromJson(String value) {
  switch (value) {
    case 'FIRST_DAY_UNDER_LIMIT':
      return AchievementRule.firstDayUnderLimit;
    case 'STREAK_DAYS':
      return AchievementRule.streakDays;
    case 'FOCUS_SESSIONS_COMPLETED':
      return AchievementRule.focusSessionsCompleted;
    case 'DAYS_UNDER_80_IN_A_ROW':
      return AchievementRule.daysUnder80InARow;
  }
  throw FormatException('Unknown achievement rule: $value');
}

// This maps one entry from the catalog of achievements
class Achievement {
  final String id;
  final String name;
  final String description;
  final String image;
  final AchievementRule rule;
  final int target;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rule,
    required this.target,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      image: json['image'] as String,
      rule: _ruleFromJson(json['rule'] as String),
      target: json['target'] as int,
    );
  }

  /// The image path is relative to the backend root, the same as the pets.
  Uri imageUri(Uri baseUrl) => baseUrl.resolve(image);
}
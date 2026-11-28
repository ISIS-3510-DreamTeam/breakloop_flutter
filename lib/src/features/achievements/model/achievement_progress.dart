import 'achievement.dart';

class AchievementProgress {
    final Achievement achievement;
    final int current;
    final bool unlocked;
    final DateTime? unlockedAt;

    const AchievementProgress({
      required this.achievement,
      required this.current,
      required this.unlocked,
      this.unlockedAt
    });


    double get fraction => achievement.target == 0
        ? 0
        : (current/ achievement.target).clamp(0.0, 1.0).toDouble();

    AchievementProgress withUnlockedAt(DateTime? date) => AchievementProgress(
        achievement: achievement,
        current: current,
        unlocked: unlocked || date != null,
        unlockedAt: date
    );
    
}
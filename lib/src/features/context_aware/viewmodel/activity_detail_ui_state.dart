import '../model/activity_phase.dart';
import '../model/offline_activity.dart';

sealed class ActivityDetailUiState {
  const ActivityDetailUiState();
}

class ActivityDetailLoading extends ActivityDetailUiState {
  const ActivityDetailLoading();
}

class ActivityDetailNotFound extends ActivityDetailUiState {
  const ActivityDetailNotFound();
}

class ActivityDetailContent extends ActivityDetailUiState {
  final OfflineActivity activity;
  final ActivityPhase phase;
  final int remainingSeconds;
  //Another activity that is still running, so this one cannot be started
  final BlockingActivity? blockedBy;

  const ActivityDetailContent({
    required this.activity,
    required this.phase,
    required this.remainingSeconds,
    this.blockedBy,
  });

  ActivityDetailContent copyWith({ActivityPhase? phase, int? remainingSeconds, BlockingActivity? blockedBy, bool clearBlocked = false}) {
    return ActivityDetailContent(
      activity: activity,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      blockedBy: clearBlocked ? null : blockedBy ?? this.blockedBy,
    );
  }
}

class BlockingActivity {
  final String activityId;
  final String title;

  const BlockingActivity({required this.activityId, required this.title});
}

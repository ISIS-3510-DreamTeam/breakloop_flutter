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

  const ActivityDetailContent({
    required this.activity,
    required this.phase,
    required this.remainingSeconds,
  });

  ActivityDetailContent copyWith({ActivityPhase? phase, int? remainingSeconds}) {
    return ActivityDetailContent(
      activity: activity,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

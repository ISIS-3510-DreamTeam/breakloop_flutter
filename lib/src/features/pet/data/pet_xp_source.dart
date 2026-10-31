import 'package:breakloop_flutter/src/features/context_aware/data/activity_log_repository.dart';
import 'package:breakloop_flutter/src/features/focus_session/data/focus_session_repository.dart';

/// Equivale a los dos observeXpSince de Room: suma el XP desde el inicio del día
/// y vuelve a emitir cada vez que cambian los datos.
class PetXpSource {
  PetXpSource({
    required this._activityLogs,
    required this._focusSessions,
  });

  final ActivityLogRepository _activityLogs;
  final FocusSessionRepository _focusSessions;

  Stream<int> observeActivityXpSince(DateTime startOfDay) async* {
    yield await _activityXp(startOfDay);
    yield* _activityLogs.watchChanges().asyncMap((_) => _activityXp(startOfDay));
  }

  Stream<int> observeFocusXpSince(DateTime startOfDay) async* {
    yield await _focusXp(startOfDay);
    yield* _focusSessions.watchChanges().asyncMap((_) => _focusXp(startOfDay));
  }

  // SUM(xp) WHERE completedAt >= startOfDay
  Future<int> _activityXp(DateTime startOfDay) async {
    final logs = await _activityLogs.getCompletedLogsOfCurrentUser();
    var total = 0;
    for (final log in logs) {
      final done = log.completedAt;
      if (done != null && !done.isBefore(startOfDay)) total += log.xp;
    }
    return total;
  }

  // SUM(xpEarned) WHERE startTime >= startOfDay
  // SUPUESTO: los campos se llaman startedAt y xpEarned. Confírmalos en FocusSessionModel.
  Future<int> _focusXp(DateTime startOfDay) async {
    final sessions = await _focusSessions.getLocalSessions();
    var total = 0;
    for (final s in sessions) {
      if (!s.startTime.isBefore(startOfDay)) total += s.xpEarned;
    }
    return total;
  }
}
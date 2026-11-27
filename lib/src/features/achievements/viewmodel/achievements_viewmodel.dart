import 'package:flutter/foundation.dart';

import '../../auth/data/auth_repository.dart';
import '../../focus_session/data/focus_session_repository.dart';
import '../../focus_session/model/focus_session_model.dart';
import '../../goals/data/goals_repository.dart';
import '../../screen_time_progress/data/screen_time_repository.dart';
import '../data/achievements_repository.dart';
import '../model/achievement_progress.dart';
import '../model/evaluation_input.dart';

enum AchievementsStatus { loading, content, empty, error }

class AchievementsViewModel extends ChangeNotifier {
  AchievementsViewModel({
    required this._auth,
    required this._achievements,
    required this._goals,
    required this._screenTime,
    required this._focus,
  });

  final AuthRepository _auth;
  final AchievementsRepository _achievements;
  final GoalsRepository _goals;
  final ScreenTimeRepository _screenTime;
  final FocusSessionRepository _focus;

  bool _disposed = false;
  int _requestId = 0;

  AchievementsStatus status = AchievementsStatus.loading;
  List<AchievementProgress> items = const [];
  bool fromCache = false;

  // Unlocks that are still waiting to reach the cloud. Read by the UI.
  int pendingUnlocks = 0;

  Future<void> load() async {
    final requestId = ++_requestId;
    status = AchievementsStatus.loading;
    _notify();

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw StateError('No signed-in user');

      final catalog = await _achievements.loadCatalog();
      final input = await _buildInput();
      final progress = await _achievements.evaluate(
        uid: uid,
        catalog: catalog.catalog,
        input: input,
      );
      // evaluate() already tried to upload, so this is what is still left.
      final pending = await _achievements.pendingCount(uid);

      // Ignore results from an older request that finished later.
      if (requestId != _requestId) return;

      items = progress;
      fromCache = catalog.fromCache;
      pendingUnlocks = pending;
      status =
      items.isEmpty ? AchievementsStatus.empty : AchievementsStatus.content;
    } catch (e, st) {
      debugPrint('[AchievementsViewModel] load failed: $e\n$st');
      if (requestId == _requestId) status = AchievementsStatus.error;
    }
    _notify();
  }

  Future<EvaluationInput> _buildInput() async {
    final goal = await _goals.getCurrentGoal();
    final days = await _screenTime.getStoredDailyScreenTime();
    final sessions = await _focus.getLocalSessions();

    return EvaluationInput(
      days: [for (final d in days) DayUsage(date: d.date, minutes: d.minutes)],
      dailyLimitMinutes: goal.dailyLimitMinutes,
      streak: goal.currentStreak,
      completedFocusSessions: sessions
          .where((s) => s.sessionStatus == SessionStatus.completed)
          .length,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
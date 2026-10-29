import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/activity_log_repository.dart';
import '../data/activity_repository.dart';
import '../data/context_provider.dart';
import '../model/activity_phase.dart';
import '../model/activity_source.dart';
import 'activity_detail_ui_state.dart';

class ActivityDetailViewModel extends ChangeNotifier {
  final String _activityId;
  final ActivitySource _source;
  final ActivityRepository _activityRepository;
  final ActivityLogRepository _activityLogRepository;
  final ContextProvider _contextProvider;

  ActivityDetailUiState uiState = const ActivityDetailLoading();

  String? _logId;
  Timer? _timer;
  bool _disposed = false;

  ActivityDetailViewModel(
    this._activityId,
    bool fromSuggestion,
    this._activityRepository,
    this._activityLogRepository,
    this._contextProvider,
  ) : _source = fromSuggestion ? ActivitySource.recommended : ActivitySource.browsed {
    _load();
  }

  ActivityDetailContent? get _content {
    final state = uiState;
    return state is ActivityDetailContent ? state : null;
  }

  Future<void> _load() async {
    final activity = await _activityRepository.getActivity(_activityId);
    if (_disposed) return;
    if (activity == null) {
      uiState = const ActivityDetailNotFound();
    } else {
      uiState = ActivityDetailContent(
        activity: activity,
        phase: ActivityPhase.ready,
        remainingSeconds: activity.durationMin * 60,
      );
    }
    notifyListeners();
  }

  //Starts the countdown and saves the log with the current context
  void start() {
    final current = _content;
    if (current == null) return;

    //In case Start is tapped twice
    _timer?.cancel();
    uiState = current.copyWith(phase: ActivityPhase.running);
    notifyListeners();

    _saveStart(current.activity.id, current.activity.durationMin);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final content = _content;
      if (content == null) return;

      if (content.remainingSeconds > 1) {
        uiState = content.copyWith(remainingSeconds: content.remainingSeconds - 1);
        notifyListeners();
      } else {
        _complete(content.copyWith(remainingSeconds: 0));
      }
    });
  }

  //The user finishes the activity before the countdown ends
  void finish() {
    final current = _content;
    if (current == null) return;
    _complete(current);
  }

  Future<void> _saveStart(String activityId, int durationMin) async {
    final snapshot = await _contextProvider.getSnapshot(durationMin);
    _logId = await _activityLogRepository.startLog(activityId, _source, snapshot);
  }

  void _complete(ActivityDetailContent current) {
    _timer?.cancel();
    uiState = current.copyWith(phase: ActivityPhase.completed);
    notifyListeners();

    final logId = _logId;
    if (logId != null) {
      _activityLogRepository.completeLog(logId, current.activity.xp);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

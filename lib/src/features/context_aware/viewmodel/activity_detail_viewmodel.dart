import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/activity_log_repository.dart';
import '../data/activity_repository.dart';
import '../data/context_provider.dart';
import '../data/place_data_source.dart';
import '../data/suggestion_interaction_repository.dart';
import '../model/suggestion_interaction.dart';
import '../model/activity_category.dart';
import '../model/activity_phase.dart';
import '../model/activity_source.dart';
import 'activity_detail_ui_state.dart';

//Same logic as ActivityDetailViewModel in the Kotlin app (PR #58): the timer is restored from the open log,
//so it continues after leaving the view or closing the app
class ActivityDetailViewModel extends ChangeNotifier {
  final String _activityId;
  final ActivitySource _source;
  final ActivityRepository _activityRepository;
  final ActivityLogRepository _activityLogRepository;
  final ContextProvider _contextProvider;
  final PlaceDataSource _placeDataSource;
  final SuggestionInteractionRepository _interactionRepository;
  final String? _interactionId;

  ActivityDetailUiState uiState = const ActivityDetailLoading();

  String? _logId;
  //When the timer ends. The remaining time is always calculated from it, so it is right after a restore
  DateTime? _endAt;
  Timer? _timer;
  //Saving the start of the log, finish waits for it to have the log id
  Future<void>? _startFuture;
  StreamSubscription<void>? _changesSubscription;
  bool _disposed = false;

  ActivityDetailViewModel(
    this._activityId,
    bool fromSuggestion,
    this._activityRepository,
    this._activityLogRepository,
    this._contextProvider,
    this._placeDataSource,
    this._interactionRepository,
    this._interactionId,
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
      notifyListeners();
      return;
    }

    final open = await _activityLogRepository.getOpenLog(activityId: _activityId);
    if (_disposed) return;

    //Not started: ready, unless another activity is running
    if (open == null) {
      uiState = ActivityDetailContent(
        activity: activity,
        phase: ActivityPhase.ready,
        remainingSeconds: activity.durationMin * 60,
      );
      notifyListeners();
      _changesSubscription = _activityLogRepository.watchChanges().listen((_) => _checkBlocked());
      await _checkBlocked();
      return;
    }

    //Started before: continue the timer, or finish it if the time already passed
    _logId = open.id;
    final endAt = open.startedAt.add(Duration(minutes: activity.durationMin));
    _endAt = endAt;
    uiState = ActivityDetailContent(
      activity: activity,
      phase: ActivityPhase.running,
      remainingSeconds: _remainingSeconds(endAt),
    );
    notifyListeners();
    if (DateTime.now().isBefore(endAt)) {
      _startTicker();
    } else {
      finish();
    }
  }

  //Another activity with an open log blocks this one, like in the Kotlin app
  Future<void> _checkBlocked() async {
    final current = _content;
    if (current == null || current.phase != ActivityPhase.ready) return;

    final open = await _activityLogRepository.getOpenLog();
    BlockingActivity? blockedBy;
    if (open != null && open.activityId != _activityId) {
      final blocking = await _activityRepository.getActivity(open.activityId);
      blockedBy = BlockingActivity(activityId: open.activityId, title: blocking?.title ?? '');
    }
    final latest = _content;
    if (_disposed || latest == null || latest.phase != ActivityPhase.ready) return;
    uiState = latest.copyWith(blockedBy: blockedBy, clearBlocked: blockedBy == null);
    notifyListeners();
  }

  //Starts the countdown and saves the log with the current context
  void start() {
    final current = _content;
    if (current == null || current.phase != ActivityPhase.ready || current.blockedBy != null) return;

    final endAt = DateTime.now().add(Duration(minutes: current.activity.durationMin));
    _endAt = endAt;
    uiState = current.copyWith(phase: ActivityPhase.running, remainingSeconds: _remainingSeconds(endAt));
    notifyListeners();

    _startFuture = _saveStart(current.activity.id, current.activity.category, current.activity.durationMin);
    _startTicker();
  }

  void _startTicker() {
    //In case Start is tapped twice
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final content = _content;
      final endAt = _endAt;
      if (content == null || endAt == null) return;

      if (DateTime.now().isBefore(endAt)) {
        uiState = content.copyWith(remainingSeconds: _remainingSeconds(endAt));
        notifyListeners();
      } else {
        finish();
      }
    });
  }

  //Seconds until endAt, rounded up so the timer shows 00:01 until the very end
  int _remainingSeconds(DateTime endAt) {
    final remainingMs = endAt.difference(DateTime.now()).inMilliseconds;
    return remainingMs <= 0 ? 0 : (remainingMs + 999) ~/ 1000;
  }

  //The log keeps the category and the place for BQ12
  Future<void> _saveStart(String activityId, ActivityCategory category, int durationMin) async {
    final snapshot = await _contextProvider.getSnapshot(durationMin);
    final place = await _placeDataSource.getPlace();
    _logId = await _activityLogRepository.startLog(activityId, category, _source, snapshot, place, _interactionId);

    //Starting the activity closes the interaction of the Offline view (BQ12)
    final interactionId = _interactionId;
    if (interactionId != null) {
      final accepted = _source == ActivitySource.recommended;
      await _interactionRepository.closeInteraction(
        interactionId,
        outcome: accepted ? InteractionOutcome.accepted : InteractionOutcome.otherActivity,
        acceptedActivityId: accepted ? activityId : null,
        chosenActivityId: activityId,
      );
    }
  }

  //Ends the activity: when the timer reaches zero or when the user taps "I'm done"
  Future<void> finish() async {
    _timer?.cancel();
    final current = _content;
    if (current == null || current.phase == ActivityPhase.completed) return;
    uiState = current.copyWith(phase: ActivityPhase.completed, remainingSeconds: 0);
    notifyListeners();

    await _startFuture;
    final logId = _logId;
    if (logId == null) return;
    //A timer that ended while the app was closed is completed at its end, not when the user came back
    final endAt = _endAt;
    final now = DateTime.now();
    final completedAt = endAt != null && endAt.isBefore(now) ? endAt : now;
    await _activityLogRepository.completeLog(logId, current.activity.xp, completedAt: completedAt);
  }

  @override
  void dispose() {
    _disposed = true;
    //The log stays open, so the timer can be restored when the view is opened again
    _timer?.cancel();
    _changesSubscription?.cancel();
    super.dispose();
  }
}

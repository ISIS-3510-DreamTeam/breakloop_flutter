import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/activity_log_repository.dart';
import '../data/activity_repository.dart';

sealed class ActiveActivityUiState {
  const ActiveActivityUiState();
}

class ActiveActivityHidden extends ActiveActivityUiState {
  const ActiveActivityHidden();
}

class ActiveActivityRunning extends ActiveActivityUiState {
  final String activityId;
  final String title;
  final int remainingSeconds;

  const ActiveActivityRunning({required this.activityId, required this.title, required this.remainingSeconds});
}

//The time ended while the user was in another view or the app was closed
class ActiveActivityFinished extends ActiveActivityUiState {
  final String activityId;
  final String title;

  const ActiveActivityFinished({required this.activityId, required this.title});
}

//Activity in progress, shown in a banner under the header in every tab. Same as ActiveActivityViewModel in the Kotlin app
class ActiveActivityViewModel extends ChangeNotifier {
  final ActivityLogRepository _activityLogRepository;
  final ActivityRepository _activityRepository;

  ActiveActivityUiState uiState = const ActiveActivityHidden();

  String? _activityId;
  String _title = '';
  DateTime? _endAt;
  Timer? _ticker;
  StreamSubscription<void>? _changesSubscription;

  ActiveActivityViewModel(this._activityLogRepository, this._activityRepository) {
    //A log started or completed changes the banner
    _changesSubscription = _activityLogRepository.watchChanges().listen((_) => _loadOpenLog());
    _loadOpenLog();
  }

  Future<void> _loadOpenLog() async {
    final open = await _activityLogRepository.getOpenLog();
    final activity = open == null ? null : await _activityRepository.getActivity(open.activityId);
    if (open == null || activity == null) {
      _activityId = null;
      _endAt = null;
      _ticker?.cancel();
      _ticker = null;
      _update();
      return;
    }
    _activityId = activity.id;
    _title = activity.title;
    _endAt = open.startedAt.add(Duration(minutes: activity.durationMin));
    //Updates the remaining time every second while there is an open activity
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _update());
    _update();
  }

  void _update() {
    final activityId = _activityId;
    final endAt = _endAt;
    if (activityId == null || endAt == null) {
      uiState = const ActiveActivityHidden();
    } else {
      final remainingMs = endAt.difference(DateTime.now()).inMilliseconds;
      uiState = remainingMs <= 0
          ? ActiveActivityFinished(activityId: activityId, title: _title)
          : ActiveActivityRunning(activityId: activityId, title: _title, remainingSeconds: (remainingMs + 999) ~/ 1000);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _changesSubscription?.cancel();
    super.dispose();
  }
}

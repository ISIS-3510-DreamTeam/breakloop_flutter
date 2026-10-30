import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/activity_log_repository.dart';
import '../model/calculate_avoided_screen_time_use_case.dart';

//Screen time avoided with the suggested activities (BQ6), shown in the Stats view
class AvoidedScreenTimeViewModel extends ChangeNotifier {
  final ActivityLogRepository _repository;
  final CalculateAvoidedScreenTimeUseCase _useCase;

  //Null while it loads
  AvoidedScreenTime? result;

  StreamSubscription<void>? _changesSubscription;

  AvoidedScreenTimeViewModel(this._repository, [this._useCase = const CalculateAvoidedScreenTimeUseCase()]) {
    //Recalculate when an activity is completed in the Offline view
    _changesSubscription = _repository.watchChanges().listen((_) => load());
    load();
  }

  //Works offline: it only uses the logs saved on the phone
  Future<void> load() async {
    final logs = await _repository.getCompletedLogsOfCurrentUser();
    result = _useCase.calculate(logs, DateTime.now());
    notifyListeners();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    super.dispose();
  }
}

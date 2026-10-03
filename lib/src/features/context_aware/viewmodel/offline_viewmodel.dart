import 'package:flutter/foundation.dart';

import '../data/activity_repository.dart';
import '../data/context_provider.dart';
import '../model/activity_category.dart';
import '../model/recommend_activity_use_case.dart';
import 'offline_ui_state.dart';

class OfflineViewModel extends ChangeNotifier {
  final ActivityRepository _activityRepository;
  final ContextProvider _contextProvider;
  final RecommendActivityUseCase _useCase;

  OfflineUiState uiState = const OfflineLoading();

  int _availableMin = 15;
  ActivityCategory? _selectedCategory;

  //Increases on every recompute, so the result of an older recompute that finishes later is ignored
  int _requestId = 0;
  bool _disposed = false;

  OfflineViewModel(this._activityRepository, this._contextProvider, this._useCase) {
    _recompute();
  }

  void onAvailableTimeSelected(int min) {
    _availableMin = min;
    _recompute();
  }

  void onCategorySelected(ActivityCategory? category) {
    _selectedCategory = category;
    _recompute();
  }

  Future<void> _recompute() async {
    final requestId = ++_requestId;

    final catalog = await _activityRepository.getCatalog();
    final snapshot = await _contextProvider.getSnapshot(_availableMin);
    final suggestion = _useCase.recommend(catalog, snapshot);
    final activities = _selectedCategory == null
        ? catalog
        : catalog.where((activity) {
            return activity.category == _selectedCategory;
          }).toList();

    if (_disposed || requestId != _requestId) {
      return;
    }
    uiState = OfflineContent(
      suggestion: suggestion,
      availableMin: _availableMin,
      isWeatherAvailable: snapshot.weather != null,
      activities: activities,
      selectedCategory: _selectedCategory,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/activity_log_repository.dart';
import '../data/activity_repository.dart';
import '../data/context_provider.dart';
import '../data/permissions_data_source.dart';
import '../data/place_data_source.dart';
import '../model/activity_category.dart';
import '../model/place_label.dart';
import '../model/recommend_activity_use_case.dart';
import 'offline_ui_state.dart';

class OfflineViewModel extends ChangeNotifier {
  final ActivityRepository _activityRepository;
  final ContextProvider _contextProvider;
  final RecommendActivityUseCase _useCase;
  final PermissionsDataSource _permissionsDataSource;
  final PlaceDataSource _placeDataSource;
  final ActivityLogRepository _activityLogRepository;

  OfflineUiState uiState = const OfflineLoading();

  int _availableMin = 15;
  ActivityCategory? _selectedCategory;
  PlaceLabel? _selectedPlace;

  //Sends the activity logs saved offline when the connection comes back
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  //Increases on every recompute, so the result of an older recompute that finishes later is ignored
  int _requestId = 0;
  bool _disposed = false;

  OfflineViewModel(
    this._activityRepository,
    this._contextProvider,
    this._useCase,
    this._permissionsDataSource,
    this._placeDataSource,
    this._activityLogRepository, {
    Connectivity? connectivity,
  }) {
    _connectivitySubscription = (connectivity ?? Connectivity()).onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        _activityLogRepository.syncActivityLogs();
      }
    });
    _activityLogRepository.syncActivityLogs();
    _loadPlace();
  }

  Future<void> _loadPlace() async {
    _selectedPlace = await _placeDataSource.getPlace();
    _recompute();
  }

  //Tapping the selected place again clears it
  Future<void> onPlaceSelected(PlaceLabel? place) async {
    _selectedPlace = place;
    final state = uiState;
    if (state is OfflineContent) {
      uiState = OfflineContent(
        suggestion: state.suggestion,
        availableMin: state.availableMin,
        isWeatherAvailable: state.isWeatherAvailable,
        activities: state.activities,
        selectedCategory: state.selectedCategory,
        needsLocationPermission: state.needsLocationPermission,
        selectedPlace: place,
      );
      notifyListeners();
    }
    await _placeDataSource.setPlace(place);
  }

  void onAvailableTimeSelected(int min) {
    _availableMin = min;
    _recompute();
  }

  void onCategorySelected(ActivityCategory? category) {
    _selectedCategory = category;
    _recompute();
  }

  //Asks for the location and builds the suggestion again, now with the weather if it was granted
  Future<void> requestLocationPermission() async {
    await _permissionsDataSource.requestLocationAccess();
    _recompute();
  }

  Future<void> _recompute() async {
    final requestId = ++_requestId;

    final catalog = await _activityRepository.getCatalog();
    final snapshot = await _contextProvider.getSnapshot(_availableMin);
    final suggestion = _useCase.recommend(catalog, snapshot);
    final hasLocationAccess = await _permissionsDataSource.hasLocationAccess();
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
      needsLocationPermission: !hasLocationAccess,
      selectedPlace: _selectedPlace,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

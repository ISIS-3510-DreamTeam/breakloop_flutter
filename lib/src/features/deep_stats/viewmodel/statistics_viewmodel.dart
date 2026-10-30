
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/accelerometer_adapter.dart';
import '../data/phone_check_repository.dart';
import '../model/phone_check_service.dart';

/// ViewModel that manages the data shown in the Statistics screen
class StatisticsViewModel extends ChangeNotifier {
  // Service that handles the phone check logic.
  late final PhoneCheckService _service;

  // Repository that stores and synchronizes phone pickups.
  late final PhoneCheckRepository _repository;

  // Subscriptions used to listen for updates.
  StreamSubscription<bool>? _subscription;
  StreamSubscription<void>? _statsSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _disposed = false;

  /// Statistics shown in the View.
  int _dailyPickups = 0;
  int _avgIntervalMinutes = 0;
  String _baselineText = '-';
  final bool _isListening = true;

  // Values for the Mindful Unlock card.
  int _mindfulPercentage = 0;
  int _impulsivePercentage = 0;

  // Getters exposed to the View.
  int get dailyPickups => _dailyPickups;
  int get avgIntervalMinutes => _avgIntervalMinutes;
  String get baselineText => _baselineText;
  bool get isListening => _isListening;
  int get mindfulPercentage => _mindfulPercentage;
  int get impulsivePercentage => _impulsivePercentage;

  // Creates the objects needed to get and process the data.
  StatisticsViewModel() {
    final adapter = SensorsPlusAccelerometerAdapter();
    _repository = PhoneCheckRepository();

    _service = PhoneCheckService(adapter, _repository);

    // Load the initial statistics.
    unawaited(_loadData());

    // Listen for pickup detections and statistics updates.
    _initListening();

    // Retry synchronization when connectivity returns.
    _listenToConnectivity();
  }

  // Loads and calculates the statistics from the Service.
  Future<void> _loadData() async {
    final dailyPickups = await _service.getTodayPickupCount();
    final avgInterval = await _service.getAverageIntervalMinutes();
    final baseline = await _service.getBaselineDifferenceText();
    final mindful = await _service.getMindfulPercentage();
    final impulsive = await _service.getImpulsivePercentage();

    if (_disposed) return;

    _dailyPickups = dailyPickups;
    _avgIntervalMinutes = avgInterval;
    _baselineText = baseline;
    _mindfulPercentage = mindful;
    _impulsivePercentage = impulsive;

    notifyListeners();
  }

  // Listens for new phone check detections and statistics updates.
  void _initListening() {
    _subscription = _service.onPhoneCheckDetected.listen((isDetected) {
      if (isDetected && _isListening) {
        unawaited(_loadData());
      }
    });

    _statsSubscription = _service.onStatsUpdated.listen((_) {
      unawaited(_loadData());
    });
  }

  // Listens for connectivity changes.
  void _listenToConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );

      if (hasConnection) {
        unawaited(_syncPendingPickups());
      }
    });
  }

  // Attempts to synchronize locally stored pickups with Firebase.
  Future<void> _syncPendingPickups() async {
    try {
      await _repository.syncUnsyncedPickups();
    } catch (_) {
      // Keep pending pickups locally if synchronization fails.
    }
  }

  @override
  void dispose() {
    _disposed = true;

    // Cancel subscriptions to prevent callbacks after disposal.
    _subscription?.cancel();
    _statsSubscription?.cancel();
    _connectivitySubscription?.cancel();

    _service.dispose();

    super.dispose();
  }
}

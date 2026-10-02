import 'dart:async';
import 'package:flutter/foundation.dart';

import '../data/accelerometer_adapter.dart';
import '../data/phone_check_repository.dart';
import '../model/phone_check_service.dart';

/// ViewModel that manages the data shown in the Statistics screen
class StatisticsViewModel extends ChangeNotifier {
  // Service that handles the phone check logic.
  late final PhoneCheckService _service;

  // Subscription used to listen for phone check detections
  StreamSubscription<bool>? _subscription;

  /// Statistics shown in the View.
  int _dailyPickups = 0;
  int _avgIntervalMinutes = 0;
  String _baselineText = '-';
  bool _isListening = true;

  // Values for the Mindful Unlock card
  int _mindfulPercentage = 0;
  int _impulsivePercentage = 0;

  // Getters exposed to the View.
  int get dailyPickups => _dailyPickups;
  int get avgIntervalMinutes => _avgIntervalMinutes;
  String get baselineText => _baselineText;
  bool get isListening => _isListening;

  int get mindfulPercentage => _mindfulPercentage;
  int get impulsivePercentage => _impulsivePercentage;

  // Creates the objects needed to get and process the data
  StatisticsViewModel() {
    final adapter = SensorsPlusAccelerometerAdapter();
    final repository = PhoneCheckRepository();

    _service = PhoneCheckService(adapter, repository);

    /// Load the initial statistics.
    _loadData();

    // Start listening for new phone check detections
    _initListening();
  }

  // Loads and calculates the statistics from the Service
  Future<void> _loadData() async {
    _dailyPickups = await _service.getTodayPickupCount();
    _avgIntervalMinutes = await _service.getAverageIntervalMinutes();
    _baselineText = await _service.getBaselineDifferenceText();

    // Get the percentages for the Mindful Unlock card.
    _mindfulPercentage = await _service.getMindfulPercentage();
    _impulsivePercentage = await _service.getImpulsivePercentage();

    /// Notify the View that the data has changed
    notifyListeners();
  }

  // Listens for new phone check detections
  void _initListening() {
    _subscription = _service.onPhoneCheckDetected.listen((isDetected) async {
      if (isDetected && _isListening) {


        // Update the statistics when a new pickup is detected
        await _loadData();
      }
    });

    // Listen for other updates from the Service
    _service.onStatsUpdated.listen((_) async {
      await _loadData();
    });
  }

  @override
  void dispose() {
    // Stop listening to the phone check stream
    _subscription?.cancel();

    /// Dispose the ViewModel
    super.dispose();
  }
}
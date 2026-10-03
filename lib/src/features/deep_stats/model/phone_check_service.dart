import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/accelerometer_adapter.dart';
import '../data/phone_check_repository.dart';


class PhoneCheckService {


  /// Adapter used to receive accelerometer data
  final IAccelerometerService _accelerometerAdapter;

  ///Repository used to save and retrieve phone check records
  final PhoneCheckRepository _repository;

  //7 Minimum acceleration needed to detect a phone pickup
  final double threshold;

  /// Baseline number of phone pickups used for comparison
  static const int baselinePickups = 60;

  // Time of the last detected phone pickup.
  DateTime _lastDetectionTime = DateTime.now();

  // Variables used to evaluate if the pickup was intentional
  DateTime? _pickupStartTime;
  DateTime? _lastMovementTime;
  Timer? _intentionalityTimer;
  bool _isCurrentlyPickedUp = false;

  // Last accelerometer coordinates used to calculate movement changes
  double _lastX = 0.0;
  double _lastY = 0.0;
  double _lastZ = 0.0;

  // Controller used to notify the ViewModel when statistics change
  final StreamController<void> _updateController =
      StreamController<void>.broadcast();

  Stream<void> get onStatsUpdated => _updateController.stream;

  // Creates the service using the accelerometer adapter and repository
  PhoneCheckService(
    this._accelerometerAdapter,
    this._repository, {
    this.threshold = 12.0,
  });

  // Stream that detects when a phone pickup happens
  Stream<bool> get onPhoneCheckDetected {
    return _accelerometerAdapter.accelerationStream.asyncMap((coords) async {
      final now = DateTime.now();

      // Get the acceleration values from the three axes
      double x = coords[0];
      double y = coords[1];
      double z = coords[2];

      // Calculate the total acceleration magnitude
      double magnitude = sqrt(x * x + y * y + z * z);

      // Calculate the change in each axis from the previous reading
      double deltaX = (x - _lastX).abs();
      double deltaY = (y - _lastY).abs();
      double deltaZ = (z - _lastZ).abs();
      double totalDelta = deltaX + deltaY + deltaZ;

      // Save the current coordinates for the next reading
      _lastX = x;
      _lastY = y;
      _lastZ = z;

      // Detect a strong or quick movement that could mean a phone pickup
      if (magnitude > threshold) {

        
        // Avoid counting multiple pickups too close together.
        if (now.difference(_lastDetectionTime).inMilliseconds >= 1500) {
          _lastDetectionTime = now;
          _pickupStartTime = now;
          _lastMovementTime = now;
          _isCurrentlyPickedUp = true;

          // Save the pickup time
          await _repository.savePickup(now);

          // Start checking if the pickup is intentional
          _startIntentionalityTimer();

          return true;
        }
      }

      // Monitor movement after a pickup has been detected
      else if (_isCurrentlyPickedUp && _pickupStartTime != null) {
        // Check if there is still movement in the hand
        if (totalDelta > 0.2) {
          _lastMovementTime = now;
        }

        // Check if the phone has been still for more than 1.2 seconds
        if (_lastMovementTime != null &&
            now.difference(_lastMovementTime!).inMilliseconds >= 1200) {
          final secondsElapsed =
              now.difference(_pickupStartTime!).inSeconds;

          // If the phone becomes still before 5 seconds, it is impulsive
          if (secondsElapsed < 5) {
            _intentionalityTimer?.cancel();
            _isCurrentlyPickedUp = false;
            _lastMovementTime = null;

            await _registerUnlockType(isMindful: false);
            _updateController.add(null);
          }
        }
      }

      return false;
    });
  }

  // Starts a timer to check if the pickup lasts long enough to be mindful
  void _startIntentionalityTimer() {
    _intentionalityTimer?.cancel();

    _intentionalityTimer =
        Timer(const Duration(seconds: 5), () async {
      if (_isCurrentlyPickedUp) {
        // If the phone is still being used after 5 seconds, count it as mindful
        await _registerUnlockType(isMindful: true);

        _isCurrentlyPickedUp = false;
        _lastMovementTime = null;

        // Notify that the statistics have changed
        _updateController.add(null);
      }
    });
  }

  // Saves the number of mindful and impulsive unlocks
  Future<void> _registerUnlockType({
    required bool isMindful,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    int mindful = prefs.getInt('mindful_count') ?? 0;
    int impulsive = prefs.getInt('impulsive_count') ?? 0;

    if (isMindful) {
      mindful++;
      await prefs.setInt('mindful_count', mindful);
    } else {
      impulsive++;
      await prefs.setInt('impulsive_count', impulsive);
    }
  }

  // Calculates the percentage of mindful unlocks
  Future<int> getMindfulPercentage() async {
    final prefs = await SharedPreferences.getInstance();

    int mindful = prefs.getInt('mindful_count') ?? 0;
    int impulsive = prefs.getInt('impulsive_count') ?? 0;
    int total = mindful + impulsive;

    if (total == 0) return 0;

    return ((mindful / total) * 100).round();
  }

  // Calculates the percentage of impulsive unlocks
  Future<int> getImpulsivePercentage() async {
    final prefs = await SharedPreferences.getInstance();

    int mindful = prefs.getInt('mindful_count') ?? 0;
    int impulsive = prefs.getInt('impulsive_count') ?? 0;
    int total = mindful + impulsive;

    if (total == 0) return 0;

    return ((impulsive / total) * 100).round();
  }

  // Gets all phone pickups recorded today.
  Future<List<DateTime>> _getTodayPickups() async {
    final pickups = await _repository.getPickups();
    final today = DateTime.now();

    return pickups
        .where((p) =>
            p.year == today.year &&
            p.month == today.month &&
            p.day == today.day)
        .toList();
  }

  // Returns the total number of pickups recorded today
  Future<int> getTodayPickupCount() async {
    final todayPickups = await _getTodayPickups();

    return todayPickups.length;
  }

  // Compares today's pickups with the baseline
  Future<String> getBaselineDifferenceText() async {
    final currentPickups = await getTodayPickupCount();
    final diff = currentPickups - baselinePickups;

    if (diff < 0) {
      return '$diff vs baseline';
    } else if (diff > 0) {
      return '+$diff vs baseline';
    }

    return 'Same as baseline';
  }

  // Calculates the average time between phone pickups today
  Future<int> getAverageIntervalMinutes() async {
    final todayPickups = await _getTodayPickups();

    // At least two pickups are needed to calculate an interval
    if (todayPickups.length < 2) return 0;

    final firstPickup = todayPickups.first;
    final lastPickup = todayPickups.last;

    final totalMinutes =
        lastPickup.difference(firstPickup).inMinutes;

    return (totalMinutes / (todayPickups.length - 1)).round();
  }

  // Cleans up the timer and stream controller
  void dispose() {
    _intentionalityTimer?.cancel();
    _updateController.close();
  }
}
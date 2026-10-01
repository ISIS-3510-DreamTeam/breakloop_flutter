import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/accelerometer_adapter.dart';
import '../data/phone_check_repository.dart';
import '../model/phone_check_service.dart';

class StatisticsViewModel extends ChangeNotifier {
  late final PhoneCheckService _service;
  StreamSubscription<bool>? _subscription;

  int _dailyPickups = 0;
  int _avgIntervalMinutes = 0;
  bool _isListening = true;

  int get dailyPickups => _dailyPickups;
  int get avgIntervalMinutes => _avgIntervalMinutes;
  bool get isListening => _isListening;

  StatisticsViewModel() {
    final adapter = SensorsPlusAccelerometerAdapter();
    final repository = PhoneCheckRepository();
    _service = PhoneCheckService(adapter, repository);

    _loadData();
    _initListening();
  }

  /// Carga los datos guardados en el almacenamiento local al iniciar
  Future<void> _loadData() async {
    _dailyPickups = await _service.getTodayPickupCount();
    _avgIntervalMinutes = await _service.getAverageIntervalMinutes();
    notifyListeners();
  }

  void _initListening() {
    _subscription = _service.onPhoneCheckDetected.listen((isDetected) async {
      if (isDetected && _isListening) {
        await _loadData(); // Recalcula y actualiza la UI automáticamente al detectar un pickup
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
import 'dart:math';
import '../data/accelerometer_adapter.dart';
import '../data/phone_check_repository.dart';

class PhoneCheckService {
  final IAccelerometerService _accelerometerAdapter;
  final PhoneCheckRepository _repository;
  final double threshold;

  DateTime _lastDetectionTime = DateTime.now();

  PhoneCheckService(
    this._accelerometerAdapter,
    this._repository, {
    this.threshold = 12.0,
  });

  Stream<bool> get onPhoneCheckDetected {
    return _accelerometerAdapter.accelerationStream.asyncMap((coords) async {
      final now = DateTime.now();

      if (now.difference(_lastDetectionTime).inMilliseconds < 1500) {
        return false;
      }

      double x = coords[0];
      double y = coords[1];
      double z = coords[2];
      double magnitude = sqrt(x * x + y * y + z * z);

      if (magnitude > threshold) {
        _lastDetectionTime = now;
        // Guardamos la detección localmente
        await _repository.savePickup(now);
        return true;
      }

      return false;
    });
  }

  /// CALCULO: Pickups realizados únicamente hoy
  Future<int> getTodayPickupCount() async {
    final pickups = await _repository.getPickups();
    final today = DateTime.now();
    return pickups.where((p) => 
      p.year == today.year && 
      p.month == today.month && 
      p.day == today.day
    ).length;
  }

  /// CALCULO: Intervalo promedio en minutos entre pickups hoy
  Future<int> getAverageIntervalMinutes() async {
    final pickups = await _repository.getPickups();
    final today = DateTime.now();
    
    final todayPickups = pickups.where((p) => 
      p.year == today.year && 
      p.month == today.month && 
      p.day == today.day
    ).toList();

    if (todayPickups.length < 2) return 0; // Se necesitan al menos 2 pickups para calcular un intervalo

    // Diferencia total entre el primer y último pickup del día
    final firstPickup = todayPickups.first;
    final lastPickup = todayPickups.last;
    final totalMinutes = lastPickup.difference(firstPickup).inMinutes;

    return (totalMinutes / (todayPickups.length - 1)).round();
  }
}
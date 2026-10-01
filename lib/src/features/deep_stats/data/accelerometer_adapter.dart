import 'package:sensors_plus/sensors_plus.dart';

abstract class IAccelerometerService {
  Stream<List<double>> get accelerationStream;
}

/// PATRÓN ADAPTER
class SensorsPlusAccelerometerAdapter implements IAccelerometerService {
  @override
  Stream<List<double>> get accelerationStream {
    // Usamos el acelerómetro estándar (físico directo)
    return accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).map((event) => [event.x, event.y, event.z]);
  }
}
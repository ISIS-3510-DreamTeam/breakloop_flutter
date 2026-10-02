import 'package:sensors_plus/sensors_plus.dart';
// Interface that defines what the app needs from an accelerometer
abstract class IAccelerometerService {
  // The accelerometer continuously provides X, Y and Z values
  Stream<List<double>> get accelerationStream;
}

// ADAPTER PATTERN
// This class adapts the sensors_plus library to our own interfac
class SensorsPlusAccelerometerAdapter implements IAccelerometerService {
  @override
  Stream<List<double>> get accelerationStream {
    // Listen to the accelerometer events from the device.
    return accelerometerEventStream(

      // Set the frequency at which the sensor data is received
      samplingPeriod: SensorInterval.normalInterval,
    ).map((event) {

      // Convert the library's event into the format used by our app
      
      return [event.x, event.y, event.z];
    });
  }
}
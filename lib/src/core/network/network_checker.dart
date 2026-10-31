
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  const NetworkChecker._();

  /// Como en Kotlin, solo comprueba que haya una red activa, no que realmente llegue a internet.
  static Future<bool> isOnline() async {
    final results = await Connectivity().checkConnectivity(); // connectivity_plus >= 6
    return results.any((r) => r != ConnectivityResult.none);
  }
}
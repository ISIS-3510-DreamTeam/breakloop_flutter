import 'package:geolocator/geolocator.dart';

import '../model/coordinates.dart';
import 'permissions_data_source.dart';

//Approximate location of the user. Returns null without permission, on error, or if it takes more than 2 seconds
class LocationDataSource {
  final PermissionsDataSource _permissionsDataSource;

  LocationDataSource(this._permissionsDataSource);

  Future<Coordinates?> getApproximateLocation() async {
    if (!await _permissionsDataSource.hasLocationAccess()) {
      return null;
    }
    try {
      final position = await _currentOrLastPosition().timeout(const Duration(seconds: 2));
      if (position == null) {
        return null;
      }
      return Coordinates(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }

  //Low accuracy is enough to know the weather and uses less battery.
  //If the current position fails (e.g. location turned off), we use the last known one
  Future<Position?> _currentOrLastPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }
}

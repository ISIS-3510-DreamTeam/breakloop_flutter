import 'package:geolocator/geolocator.dart';

//Location permission, needed to know the weather where the user is
class PermissionsDataSource {
  Future<bool> hasLocationAccess() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  //Shows the Android dialog. If the user denied it permanently, Android does not show it again
  Future<void> requestLocationAccess() async {
    await Geolocator.requestPermission();
  }
}

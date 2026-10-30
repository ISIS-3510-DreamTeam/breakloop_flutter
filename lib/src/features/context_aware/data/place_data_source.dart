import 'package:shared_preferences/shared_preferences.dart';

import '../model/place_label.dart';

//Last place chosen by the user in the Offline view, same as PlacePreferenceDataSource in the Kotlin app
class PlaceDataSource {
  static const _keyPlace = 'place';

  Future<PlaceLabel?> getPlace() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyPlace);
    if (saved == null) return null;
    return PlaceLabel.values.where((place) => place.name == saved).firstOrNull;
  }

  //Null removes the place
  Future<void> setPlace(PlaceLabel? place) async {
    final prefs = await SharedPreferences.getInstance();
    if (place == null) {
      await prefs.remove(_keyPlace);
    } else {
      await prefs.setString(_keyPlace, place.name);
    }
  }
}

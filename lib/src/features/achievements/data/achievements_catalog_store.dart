import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the last catalog received from the backend, for when there is no network.
class AchievementsCatalogStore {
  static const _key = 'achievements_catalog_json';

  Future<void> save(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json);
  }

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
}
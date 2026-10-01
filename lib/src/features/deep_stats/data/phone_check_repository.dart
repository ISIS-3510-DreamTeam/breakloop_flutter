import 'package:shared_preferences/shared_preferences.dart';

class PhoneCheckRepository {
  static const String _keyPickups = 'phone_check_timestamps';

  /// Guarda una nueva fecha/hora de pickup en el teléfono
  Future<void> savePickup(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_keyPickups) ?? [];
    records.add(timestamp.toIso8601String());
    await prefs.setStringList(_keyPickups, records);
  }

  /// Recupera todas las fechas/horas guardadas
  Future<List<DateTime>> getPickups() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> records = prefs.getStringList(_keyPickups) ?? [];
    return records.map((e) => DateTime.parse(e)).toList();
  }
}
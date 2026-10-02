import 'package:shared_preferences/shared_preferences.dart';

/// Repository responsible for storing and retrieving phone pickup records.
class PhoneCheckRepository {


  /// Key used to store the pickup timestamps.
  static const String _keyPickups = 'phone_check_timestamps';

  //7 Saves the date and time of a new phone pickup
  Future<void> savePickup(DateTime timestamp) async {

    // Get access to the phone's local storage.
    final prefs = await SharedPreferences.getInstance();

    // Get the existing records, or create an empty list if there are none
    List<String> records = prefs.getStringList(_keyPickups) ?? [];

    // Convert the timestamp to text and add it to the records
    records.add(timestamp.toIso8601String());

    /// Save the updated list back to local storage
    await prefs.setStringList(_keyPickups, records);
  }

  // Retrieves all the pickup dates and times stored on the phon
  Future<List<DateTime>> getPickups() async {

    // Get access to the phone's local storage.
    final prefs = await SharedPreferences.getInstance();

    /// Get all stored records, or an empty list if there are none
    List<String> records = prefs.getStringList(_keyPickups) ?? [];

    // Convert the stored text back into DateTime objects
    return records.map((e) => DateTime.parse(e)).toList();
  }

  // Retrieves only the pickups recorded today
  Future<List<DateTime>> getTodayPickups() async {
    // Get all the stored pickups.
    final allPickups = await getPickups();
    final now = DateTime.now();
    return allPickups.where((pickup) {
      return pickup.year == now.year &&
          pickup.month == now.month &&
          pickup.day == now.day;
    }).toList();
  }

  // Removes old pickups and keeps only today's records
  Future<void> clearOldPickups() async {
    // Get only today's pickups
    final todayPickups = await getTodayPickups();

    // Get access to the phone's local storage
    final prefs = await SharedPreferences.getInstance();

    /// Convert today's records back into text
    final records =
        todayPickups.map((e) => e.toIso8601String()).toList();

    // Replace the stored records with only today's pickups
    await prefs.setStringList(_keyPickups, records);
  }
}
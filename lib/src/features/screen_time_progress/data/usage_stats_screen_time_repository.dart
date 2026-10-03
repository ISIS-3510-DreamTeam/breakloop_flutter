import 'package:flutter/services.dart';
import '../model/daily_screen_time.dart';
import 'screen_time_repository.dart';

//Real screen time of the phone, read from Android's UsageStatsManager through native code.
//It needs the PACKAGE_USAGE_STATS permission, which the user has to enable in the Android settings.
class UsageStatsScreenTimeRepository implements ScreenTimeRepository {
  //Must match the channel name defined in MainActivity.kt
  static const _channel = MethodChannel('breakloop/usage_stats');

  @override
  Future<bool> hasPermission() async {
    final granted = await _channel.invokeMethod<bool>('hasUsagePermission');
    return granted ?? false;
  }

  //Opens the Android usage access settings. The permission cannot be requested with a dialog.
  @override
  Future<void> requestPermission() async {
    await _channel.invokeMethod<void>('openUsageSettings');
  }

  @override
  Future<List<DailyScreenTime>> getDailyScreenTime() async {
    //Day ("yyyy-MM-dd") -> minutes of screen time of that day
    final minutesByDay = await _channel.invokeMapMethod<String, int>('getDailyUsage');
    if (minutesByDay == null) {
      return [];
    }

    return [
      for (final entry in minutesByDay.entries)
        DailyScreenTime(date: DateTime.parse(entry.key), minutes: entry.value),
    ];
  }

}

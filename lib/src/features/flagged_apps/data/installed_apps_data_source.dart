import 'package:flutter/services.dart';

import '../model/installed_app.dart';

//Reads the installed apps, their icons and today's usage from Android through native code (MainActivity.kt).
//The native side runs this work in a background thread, like Dispatchers.IO in the Kotlin app
class InstalledAppsDataSource {
  //Must match APPS_CHANNEL in MainActivity.kt
  static const _channel = MethodChannel('breakloop/installed_apps');

  //Launcher apps without BreakLoop, sorted by name
  Future<List<InstalledApp>> getInstalledApps() async {
    final apps = await _channel.invokeListMethod<Map>('getInstalledApps') ?? [];
    final result = [
      for (final app in apps)
        InstalledApp(packageName: app['packageName'] as String, label: app['label'] as String),
    ];
    result.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return result;
  }

  //PNG bytes of the app icon, or null if it cannot be loaded
  Future<Uint8List?> getAppIcon(String packageName, int sizePx) {
    return _channel.invokeMethod<Uint8List>('getAppIcon', {'packageName': packageName, 'sizePx': sizePx});
  }

  //Milliseconds in the foreground of each app today. Empty without the usage permission
  Future<Map<String, int>> getTodayAppUsage() async {
    final usage = await _channel.invokeMapMethod<String, int>('getTodayAppUsage');
    return usage ?? {};
  }
}

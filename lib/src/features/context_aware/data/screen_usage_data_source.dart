import 'package:flutter/services.dart';

//Reads from Android how long the phone was used in a time window, through native code (MainActivity.kt)
class ScreenUsageDataSource {
  //Must match the channel name defined in MainActivity.kt
  static const _channel = MethodChannel('breakloop/usage_stats');

  //Milliseconds with another app in the foreground (BreakLoop is not counted),
  //or null without the usage permission or if it cannot be read
  Future<int?> getScreenTimeBetween(DateTime start, DateTime end) async {
    try {
      return await _channel.invokeMethod<int>('getScreenTimeBetween', {
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
      });
    } on PlatformException {
      return null;
    }
  }
}

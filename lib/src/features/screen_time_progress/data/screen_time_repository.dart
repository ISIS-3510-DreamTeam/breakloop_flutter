import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../model/daily_screen_time.dart';
import 'daily_usage_local_datasource.dart';
import 'daily_usage_remote_datasource.dart';

//Real screen time of the phone, read from Android's UsageStatsManager through native code.
//It needs the PACKAGE_USAGE_STATS permission, which the user has to enable in the Android settings.
//The days are saved in the local database (source of truth, works offline), kept in a short cache
//and sent to the backend when there is connection
class ScreenTimeRepository {
  //Must match the channel name defined in MainActivity.kt
  static const _channel = MethodChannel('breakloop/usage_stats');

  //Home refreshes every minute and Stats reads the same data, so a read is reused for a minute
  static const _cacheDuration = Duration(minutes: 1);

  final DailyUsageLocalDatasource _localDatasource;
  final DailyUsageRemoteDatasource _remoteDatasource;
  final FirebaseAuth _auth;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<DailyScreenTime>? _cache;
  DateTime? _cachedAt;
  //Read in progress, shared by the callers that ask at the same time
  Future<List<DailyScreenTime>>? _reading;
  bool _syncing = false;

  ScreenTimeRepository({
    DailyUsageLocalDatasource? localDatasource,
    DailyUsageRemoteDatasource? remoteDatasource,
    FirebaseAuth? auth,
    Connectivity? connectivity,
  })  : _localDatasource = localDatasource ?? DailyUsageLocalDatasource(),
        _remoteDatasource = remoteDatasource ?? DailyUsageRemoteDatasource(),
        _auth = auth ?? FirebaseAuth.instance {
    //When the connection comes back, send the days saved offline
    _connectivitySubscription = (connectivity ?? Connectivity()).onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncPending();
      }
    });
  }

  Future<bool> hasPermission() async {
    final granted = await _channel.invokeMethod<bool>('hasUsagePermission');
    return granted ?? false;
  }

  //Opens the Android usage access settings. The permission cannot be requested with a dialog.
  Future<void> requestPermission() async {
    await _channel.invokeMethod<void>('openUsageSettings');
  }

  //Days saved in the local database, without asking Android
  Future<List<DailyScreenTime>> getStoredDailyScreenTime() async {
    return [
      for (final row in await _localDatasource.getDays())
        DailyScreenTime(
          date: DateTime.parse(row['date'] as String),
          minutes: (row['screenTimeMs'] as int) ~/ Duration.millisecondsPerMinute,
        ),
    ];
  }

  //Daily records of the user, from the cache if they were read less than a minute ago
  Future<List<DailyScreenTime>> getDailyScreenTime() {
    final cache = _cache;
    final cachedAt = _cachedAt;
    if (cache != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheDuration) {
      return Future.value(cache);
    }
    return _reading ??= _readFromAndroid().whenComplete(() => _reading = null);
  }

  //Saves the time spent in the flagged apps on a day ("yyyy-MM-dd") and sends it with the rest of the day
  Future<void> saveFlaggedTime(String date, int flaggedTimeMs) async {
    await _localDatasource.saveFlaggedTime(date, flaggedTimeMs);
    unawaited(syncPending());
  }

  Future<List<DailyScreenTime>> _readFromAndroid() async {
    try {
      //Day ("yyyy-MM-dd") -> minutes of screen time of that day
      final minutesByDay = await _channel.invokeMapMethod<String, int>('getDailyUsage') ?? {};
      await _localDatasource.saveScreenTime({
        for (final MapEntry(key: date, value: minutes) in minutesByDay.entries)
          date: minutes * Duration.millisecondsPerMinute,
      });
      unawaited(syncPending());
    } catch (e) {
      //If Android cannot be read, the saved days are still shown
      final stored = await getStoredDailyScreenTime();
      if (stored.isEmpty) rethrow;
      debugPrint('[ScreenTimeRepository] could not read Android, using the saved days: $e');
      return stored;
    }
    _cachedAt = DateTime.now();
    return _cache = await getStoredDailyScreenTime();
  }

  //Sends the days that changed to the backend. If it fails, they stay pending for the next try
  Future<void> syncPending() async {
    final user = _auth.currentUser;
    //A sync already running will also send the new changes in its next try
    if (user == null || _syncing) return;
    _syncing = true;

    try {
      final days = await _localDatasource.getUnsyncedDays();
      for (final day in days) {
        final date = day['date'] as String;
        final updatedAt = day['updatedAt'] as int;
        //Same body as UsageDto in the Kotlin app. Pickups and unlocks are not measured, Kotlin also sends 0
        await _remoteDatasource.postDailyUsage(user, {
          'date': date,
          'screenTimeMs': day['screenTimeMs'],
          'pickups': 0,
          'unlocks': 0,
          'isPartial': false,
          'updatedAt': updatedAt,
          'flaggedTimeMs': day['flaggedTimeMs'],
        });
        await _localDatasource.markSynced(date, updatedAt);
      }
      if (days.isNotEmpty) debugPrint('[ScreenTimeRepository] synced ${days.length} days');
    } catch (e) {
      debugPrint('[ScreenTimeRepository] sync failed, will retry later: $e');
    } finally {
      _syncing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

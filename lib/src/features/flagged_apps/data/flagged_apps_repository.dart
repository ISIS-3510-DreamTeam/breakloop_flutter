import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../model/calculate_flagged_time_use_case.dart';
import '../model/flagged_app.dart';
import '../model/installed_app.dart';
import 'flagged_apps_local_datasource.dart';
import 'flagged_apps_remote_datasource.dart';
import 'installed_apps_data_source.dart';

/// Repository of the flagged apps. The local database is the source of truth (works offline),
/// and the changes are sent to Firestore when there is connection
class FlaggedAppsRepository {
  final FlaggedAppsLocalDatasource _localDatasource;
  final FlaggedAppsRemoteDatasource _remoteDatasource;
  final InstalledAppsDataSource _installedAppsDataSource;
  final CalculateFlaggedTimeUseCase _calculateFlaggedTime;
  final FirebaseAuth _auth;
  final Connectivity _connectivity;

  //Emits the flagged apps every time they change
  final _flaggedController = StreamController<List<FlaggedApp>>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  FlaggedAppsRepository({
    FlaggedAppsLocalDatasource? localDatasource,
    FlaggedAppsRemoteDatasource? remoteDatasource,
    InstalledAppsDataSource? installedAppsDataSource,
    this._calculateFlaggedTime = const CalculateFlaggedTimeUseCase(),
    FirebaseAuth? auth,
    Connectivity? connectivity,
  })  : _localDatasource = localDatasource ?? FlaggedAppsLocalDatasource(),
        _remoteDatasource = remoteDatasource ?? FlaggedAppsRemoteDatasource(),
        _installedAppsDataSource = installedAppsDataSource ?? InstalledAppsDataSource(),
        _auth = auth ?? FirebaseAuth.instance,
        _connectivity = connectivity ?? Connectivity() {
    //When the connection comes back, send the changes made offline
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncPending();
      }
    });
  }

  Stream<List<FlaggedApp>> watchFlaggedApps() => _flaggedController.stream;

  Future<List<FlaggedApp>> getFlaggedApps() => _localDatasource.getFlaggedApps();

  Future<List<InstalledApp>> getInstalledApps() => _installedAppsDataSource.getInstalledApps();

  Future<Uint8List?> getAppIcon(String packageName, int sizePx) => _installedAppsDataSource.getAppIcon(packageName, sizePx);

  Future<void> addFlaggedApp(String packageName, int? limit) async {
    await _localDatasource.insertOrReplaceApp(packageName, limit, DateTime.now().millisecondsSinceEpoch);
    await _afterChange();
  }

  Future<void> deleteFlaggedApp(String packageName) async {
    await _localDatasource.markDeleted(packageName);
    await _afterChange();
  }

  Future<void> changeFlaggedAppLimit(String packageName, int? limit) async {
    await _localDatasource.updateLimit(packageName, limit);
    await _afterChange();
  }

  Future<void> deleteUninstalledApps(Set<String> installedPackages) async {
    await _localDatasource.markUninstalledDeleted(installedPackages);
    await _afterChange();
  }

  //Recalculates today's screen time and the time spent in the flagged apps and saves them locally
  Future<void> refreshTodayFlaggedTime() async {
    final usage = await _installedAppsDataSource.getTodayAppUsage();
    //Without the usage permission there is nothing to measure
    if (usage.isEmpty) return;

    //Like the Kotlin app, the screen time only counts the launcher apps
    final included = {for (final app in await getInstalledApps()) app.packageName};
    var screenTimeMs = 0;
    usage.forEach((packageName, ms) {
      if (included.contains(packageName)) screenTimeMs += ms;
    });
    final flaggedTimeMs = _calculateFlaggedTime.getFlaggedAppTime(usage, await getFlaggedApps());
    await _localDatasource.saveDailyUsage(_todayKey(), screenTimeMs, flaggedTimeMs, DateTime.now().millisecondsSinceEpoch);
    debugPrint('[FlaggedAppsRepository] today screenTimeMs=$screenTimeMs flaggedTimeMs=$flaggedTimeMs');
  }

  //Sends the changes that have not been synced: the flagged apps to Firestore and the daily usage to the backend.
  //If it fails, they stay queued for the next try
  Future<void> syncPending() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    try {
      for (final (app, deleted) in await _localDatasource.getUnsyncedApps()) {
        if (deleted) {
          await _remoteDatasource.deleteFlaggedApp(uid, app.packageName);
        } else {
          await _remoteDatasource.saveFlaggedApp(uid, app);
        }
        await _localDatasource.markAppSynced(app.packageName, deleted: deleted);
      }
      for (final day in await _localDatasource.getUnsyncedDailyUsage()) {
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
        await _localDatasource.markDailyUsageSynced(date, updatedAt);
      }
    } catch (e) {
      debugPrint('[FlaggedAppsRepository] sync failed, will retry later: $e');
    }
  }

  //Every change updates the listeners, the time of today and tries to sync
  Future<void> _afterChange() async {
    _flaggedController.add(await getFlaggedApps());
    await refreshTodayFlaggedTime();
    unawaited(syncPending());
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _flaggedController.close();
  }
}

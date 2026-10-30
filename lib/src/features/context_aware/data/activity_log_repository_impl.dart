import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/activity_category.dart';
import '../model/activity_log_entry.dart';
import '../model/activity_source.dart';
import '../model/context_snapshot.dart';
import '../model/place_label.dart';
import 'activity_log_remote_data_source.dart';
import 'activity_log_repository.dart';
import 'screen_usage_data_source.dart';

//Stores the activity logs on the device as a list of JSON strings (local first)
//and sends them to the backend when there is connection
class ActivityLogRepositoryImpl implements ActivityLogRepository {
  static const _keyActivityLogs = 'activity_logs';

  //Shared by all the instances, so a screen hears the logs saved by another one
  static final _changes = StreamController<void>.broadcast();

  final ActivityLogRemoteDataSource _remote;
  final ScreenUsageDataSource _screenUsage;
  final FirebaseAuth _auth;

  ActivityLogRepositoryImpl({
    ActivityLogRemoteDataSource? remote,
    ScreenUsageDataSource? screenUsage,
    FirebaseAuth? auth,
  })  : _remote = remote ?? ActivityLogRemoteDataSource(),
        _screenUsage = screenUsage ?? ScreenUsageDataSource(),
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Stream<void> watchChanges() => _changes.stream;

  @override
  Future<String> startLog(
    String activityId,
    ActivityCategory category,
    ActivitySource source,
    ContextSnapshot context,
    PlaceLabel? placeLabel,
    String? interactionId,
  ) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final logs = await _readLogs();
    logs.add(ActivityLogEntry(
      id: id,
      activityId: activityId,
      category: category,
      source: source,
      startedAt: now,
      completedAt: null,
      xp: 0,
      partOfDay: context.partOfDay,
      weather: context.weather?.name,
      availableMin: context.availableMin,
      placeLabel: placeLabel,
      interactionId: interactionId,
      userId: _auth.currentUser?.uid,
    ));
    await _writeLogs(logs);
    _changes.add(null);
    unawaited(syncActivityLogs());
    return id;
  }

  @override
  Future<void> completeLog(String logId, int xp) async {
    final logs = await _readLogs();
    final index = logs.indexWhere((log) => log.id == logId);
    if (index == -1) return;

    final now = DateTime.now();
    final log = logs[index];
    logs[index] = log.complete(now, xp, await _avoidedScreenMs(log.startedAt, now));
    await _writeLogs(logs);
    _changes.add(null);
    unawaited(syncActivityLogs());
  }

  //Duration of the activity minus the time the phone was used meanwhile (BQ6).
  //Without the usage permission the phone use cannot be measured, so the whole duration counts
  Future<int> _avoidedScreenMs(DateTime startedAt, DateTime completedAt) async {
    final duration = completedAt.difference(startedAt).inMilliseconds;
    final used = await _screenUsage.getScreenTimeBetween(startedAt, completedAt);
    if (used == null) return duration;
    return max(0, duration - used);
  }

  @override
  Future<List<ActivityLogEntry>> getCompletedLogsOfCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    return (await _readLogs()).where((log) => log.userId == uid && log.completedAt != null).toList();
  }

  @override
  Future<List<String>> getRecentActivityIds(int limit) async {
    final completed = (await _readLogs()).where((log) {
      return log.completedAt != null;
    }).toList();
    completed.sort((a, b) {
      return b.completedAt!.compareTo(a.completedAt!);
    });
    return completed.take(limit).map((log) {
      return log.activityId;
    }).toList();
  }

  @override
  Future<void> syncActivityLogs() async {
    //Logs saved before the category existed cannot be accepted by the backend
    //Only the logs of the account that is logged in (old logs have no account and are sent with the current one)
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final pending = (await _readLogs())
        .where((log) => !log.synced && log.category != null && (log.userId == null || log.userId == uid))
        .toList();
    if (pending.isEmpty) return;

    try {
      if (!await _remote.upload(pending)) return;
    } catch (e) {
      debugPrint('[ActivityLogRepository] sync failed, will retry later: $e');
      return;
    }

    //A log completed while it was being uploaded changed, so it stays pending (same check as the Kotlin DAO)
    final uploaded = {for (final log in pending) log.id: log.completedAt};
    final logs = await _readLogs();
    await _writeLogs([
      for (final log in logs)
        uploaded.containsKey(log.id) && uploaded[log.id] == log.completedAt ? log.copyWith(synced: true) : log,
    ]);
    debugPrint('[ActivityLogRepository] synced ${pending.length} logs');
  }

  Future<List<ActivityLogEntry>> _readLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final records = prefs.getStringList(_keyActivityLogs) ?? [];
    return [
      for (final record in records) ActivityLogEntry.fromJson(jsonDecode(record) as Map<String, dynamic>),
    ];
  }

  Future<void> _writeLogs(List<ActivityLogEntry> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyActivityLogs, [
      for (final log in logs) jsonEncode(log.toJson()),
    ]);
  }
}

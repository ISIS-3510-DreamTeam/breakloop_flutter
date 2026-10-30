import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/activity_category.dart';
import '../model/activity_log_entry.dart';
import '../model/activity_source.dart';
import '../model/context_snapshot.dart';
import '../model/place_label.dart';
import 'activity_log_remote_data_source.dart';
import 'activity_log_repository.dart';

//Stores the activity logs on the device as a list of JSON strings (local first)
//and sends them to the backend when there is connection
class ActivityLogRepositoryImpl implements ActivityLogRepository {
  static const _keyActivityLogs = 'activity_logs';

  final ActivityLogRemoteDataSource _remote;

  ActivityLogRepositoryImpl({ActivityLogRemoteDataSource? remote}) : _remote = remote ?? ActivityLogRemoteDataSource();

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
    ));
    await _writeLogs(logs);
    unawaited(syncActivityLogs());
    return id;
  }

  @override
  Future<void> completeLog(String logId, int xp) async {
    final logs = await _readLogs();
    final updated = [
      for (final log in logs) log.id == logId ? log.complete(DateTime.now(), xp) : log,
    ];
    await _writeLogs(updated);
    unawaited(syncActivityLogs());
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
    final pending = (await _readLogs()).where((log) => !log.synced && log.category != null).toList();
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

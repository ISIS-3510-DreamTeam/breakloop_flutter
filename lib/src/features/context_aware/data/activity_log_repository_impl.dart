import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/activity_log_entry.dart';
import '../model/activity_source.dart';
import '../model/context_snapshot.dart';
import 'activity_log_repository.dart';

//Stores the activity logs on the device as a list of JSON strings
class ActivityLogRepositoryImpl implements ActivityLogRepository {
  static const _keyActivityLogs = 'activity_logs';

  @override
  Future<String> startLog(String activityId, ActivitySource source, ContextSnapshot context) async {
    final now = DateTime.now();
    final id = now.microsecondsSinceEpoch.toString();
    final logs = await _readLogs();
    logs.add(ActivityLogEntry(
      id: id,
      activityId: activityId,
      source: source,
      startedAt: now,
      completedAt: null,
      xp: 0,
      partOfDay: context.partOfDay,
      weather: context.weather?.name,
      availableMin: context.availableMin,
    ));
    await _writeLogs(logs);
    return id;
  }

  @override
  Future<void> completeLog(String logId, int xp) async {
    final logs = await _readLogs();
    final updated = [
      for (final log in logs) log.id == logId ? log.complete(DateTime.now(), xp) : log,
    ];
    await _writeLogs(updated);
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

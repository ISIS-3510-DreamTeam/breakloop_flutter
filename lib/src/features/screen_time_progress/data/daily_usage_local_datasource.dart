import 'package:sqflite/sqflite.dart';

//SQLite table with the usage of each day ("yyyy-MM-dd"), the same DailyUsageStats of the Kotlin app.
//It keeps the history after Android forgets old days, and isSynced marks the days that still have to reach the backend
class DailyUsageLocalDatasource {
  Database? _database;

  Future<Database> _db() async {
    return _database ??= await openDatabase(
      '${await getDatabasesPath()}/daily_usage.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE daily_usage ('
          'date TEXT PRIMARY KEY, '
          'screenTimeMs INTEGER NOT NULL DEFAULT 0, '
          'flaggedTimeMs INTEGER NOT NULL DEFAULT 0, '
          'updatedAt INTEGER NOT NULL, '
          'isSynced INTEGER NOT NULL DEFAULT 0)',
        );
      },
    );
  }

  Future<List<Map<String, Object?>>> getDays() async {
    return (await _db()).query('daily_usage', orderBy: 'date');
  }

  //Saves the screen time of each day: date -> ms. Only the days that changed are sent again
  Future<void> saveScreenTime(Map<String, int> msByDay) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _db()).transaction((txn) async {
      final rows = await txn.query('daily_usage', columns: ['date', 'screenTimeMs']);
      final stored = {for (final row in rows) row['date'] as String: row['screenTimeMs'] as int};
      for (final MapEntry(key: date, value: ms) in msByDay.entries) {
        if (!stored.containsKey(date)) {
          await txn.insert('daily_usage', {'date': date, 'screenTimeMs': ms, 'updatedAt': now, 'isSynced': 0});
        } else if (stored[date] != ms) {
          await txn.update(
            'daily_usage',
            {'screenTimeMs': ms, 'updatedAt': now, 'isSynced': 0},
            where: 'date = ?',
            whereArgs: [date],
          );
        }
      }
    });
  }

  //Saves the time spent in the flagged apps on a day, calculated by the flagged apps feature
  Future<void> saveFlaggedTime(String date, int flaggedTimeMs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (await _db()).transaction((txn) async {
      final rows = await txn.query('daily_usage', columns: ['flaggedTimeMs'], where: 'date = ?', whereArgs: [date]);
      if (rows.isEmpty) {
        await txn.insert('daily_usage', {'date': date, 'flaggedTimeMs': flaggedTimeMs, 'updatedAt': now, 'isSynced': 0});
      } else if (rows.first['flaggedTimeMs'] != flaggedTimeMs) {
        await txn.update(
          'daily_usage',
          {'flaggedTimeMs': flaggedTimeMs, 'updatedAt': now, 'isSynced': 0},
          where: 'date = ?',
          whereArgs: [date],
        );
      }
    });
  }

  Future<List<Map<String, Object?>>> getUnsyncedDays() async {
    return (await _db()).query('daily_usage', where: 'isSynced = 0');
  }

  //Only marks the day if it did not change while it was being sent (same as markSynced in the Kotlin app)
  Future<void> markSynced(String date, int updatedAt) async {
    await (await _db()).update(
      'daily_usage',
      {'isSynced': 1},
      where: 'date = ? AND updatedAt = ?',
      whereArgs: [date, updatedAt],
    );
  }
}

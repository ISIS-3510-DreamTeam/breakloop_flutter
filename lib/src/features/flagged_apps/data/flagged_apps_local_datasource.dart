import 'package:sqflite/sqflite.dart';

import '../model/flagged_app.dart';

//SQLite database with the flagged apps
//isSynced and isDeleted keep the changes that still have to be sent to Firestore
class FlaggedAppsLocalDatasource {
  Database? _database;

  Future<Database> _db() async {
    return _database ??= await openDatabase(
      '${await getDatabasesPath()}/flagged_apps.db',
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE flagged_apps ('
          'packageName TEXT PRIMARY KEY, '
          'dailyLimitMin INTEGER, '
          'flaggedAt INTEGER NOT NULL, '
          'isSynced INTEGER NOT NULL DEFAULT 0, '
          'isDeleted INTEGER NOT NULL DEFAULT 0)',
        );
        //Usage of each day ("yyyy-MM-dd"): total screen time and time in the flagged apps
        await db.execute(
          'CREATE TABLE daily_flagged_time ('
          'date TEXT PRIMARY KEY, '
          'flaggedTimeMs INTEGER NOT NULL, '
          'screenTimeMs INTEGER NOT NULL DEFAULT 0, '
          'updatedAt INTEGER NOT NULL DEFAULT 0, '
          'isSynced INTEGER NOT NULL DEFAULT 0)',
        );
      },
      //Version 2 adds the fields that the backend usage endpoint needs
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE daily_flagged_time ADD COLUMN screenTimeMs INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE daily_flagged_time ADD COLUMN updatedAt INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  //Flagged apps, without the ones deleted and waiting to be synced
  Future<List<FlaggedApp>> getFlaggedApps() async {
    final rows = await (await _db()).query('flagged_apps', where: 'isDeleted = 0');
    return rows.map(FlaggedApp.fromMap).toList();
  }

  Future<void> insertOrReplaceApp(String packageName, int? dailyLimitMin, int flaggedAt) async {
    await (await _db()).insert(
      'flagged_apps',
      {'packageName': packageName, 'dailyLimitMin': dailyLimitMin, 'flaggedAt': flaggedAt, 'isSynced': 0, 'isDeleted': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateLimit(String packageName, int? newLimit) async {
    await (await _db()).update(
      'flagged_apps',
      {'dailyLimitMin': newLimit, 'isSynced': 0},
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }

  //The row stays until the deletion reaches Firestore
  Future<void> markDeleted(String packageName) async {
    await (await _db()).update(
      'flagged_apps',
      {'isDeleted': 1, 'isSynced': 0},
      where: 'packageName = ?',
      whereArgs: [packageName],
    );
  }

  //Marks as deleted the flagged apps that are no longer installed
  Future<void> markUninstalledDeleted(Set<String> installedPackages) async {
    final db = await _db();
    final rows = await db.query('flagged_apps', columns: ['packageName'], where: 'isDeleted = 0');
    for (final row in rows) {
      final packageName = row['packageName'] as String;
      if (!installedPackages.contains(packageName)) {
        await markDeleted(packageName);
      }
    }
  }

  //Changes that have not reached Firestore yet: (app, isDeleted)
  Future<List<(FlaggedApp, bool)>> getUnsyncedApps() async {
    final rows = await (await _db()).query('flagged_apps', where: 'isSynced = 0');
    return [for (final row in rows) (FlaggedApp.fromMap(row), row['isDeleted'] == 1)];
  }

  //After the sync, deleted apps are removed and the rest are marked as synced
  Future<void> markAppSynced(String packageName, {required bool deleted}) async {
    final db = await _db();
    if (deleted) {
      await db.delete('flagged_apps', where: 'packageName = ?', whereArgs: [packageName]);
    } else {
      await db.update('flagged_apps', {'isSynced': 1}, where: 'packageName = ?', whereArgs: [packageName]);
    }
  }

  Future<void> saveDailyUsage(String date, int screenTimeMs, int flaggedTimeMs, int updatedAt) async {
    await (await _db()).insert(
      'daily_flagged_time',
      {
        'date': date,
        'flaggedTimeMs': flaggedTimeMs,
        'screenTimeMs': screenTimeMs,
        'updatedAt': updatedAt,
        'isSynced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  //Days whose usage has not reached the backend yet
  Future<List<Map<String, Object?>>> getUnsyncedDailyUsage() async {
    return (await _db()).query('daily_flagged_time', where: 'isSynced = 0');
  }

  //Only marks the day if it did not change while it was being sent (same as markSynced in the Kotlin app)
  Future<void> markDailyUsageSynced(String date, int updatedAt) async {
    await (await _db()).update(
      'daily_flagged_time',
      {'isSynced': 1},
      where: 'date = ? AND updatedAt = ?',
      whereArgs: [date, updatedAt],
    );
  }
}

import 'package:sqflite/sqflite.dart';

/// Unlocked achievements per user. isSynced is reserved for the upload step, later.
class AchievementsLocalDatasource {
  Database? _database;

  Future<Database> _db() async {
    return _database ??= await openDatabase(
      '${await getDatabasesPath()}/achievements.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE achievements ('
              'uid TEXT NOT NULL, '
              'achievementId TEXT NOT NULL, '
              'unlockedAt INTEGER NOT NULL, '
              'isSynced INTEGER NOT NULL DEFAULT 0, '
              'PRIMARY KEY (uid, achievementId))',
        );
      },
    );
  }

  /// Saves the unlocks that are not stored yet. An existing row keeps its original date.
  Future<void> insertUnlocks(String uid, Map<String, int> unlockedAtById) async {
    final db = await _db();
    final batch = db.batch();
    unlockedAtById.forEach((achievementId, unlockedAt) {
      batch.insert(
        'achievements',
        {
          'uid': uid,
          'achievementId': achievementId,
          'unlockedAt': unlockedAt,
          'isSynced': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
    await batch.commit(noResult: true);
  }

  /// Achievement id → unlock time in epoch milliseconds.
  Future<Map<String, int>> getUnlocks(String uid) async {
    final rows = await (await _db()).query(
      'achievements',
      columns: ['achievementId', 'unlockedAt'],
      where: 'uid = ?',
      whereArgs: [uid],
    );
    return {
      for (final row in rows) row['achievementId'] as String: row['unlockedAt'] as int,
    };
  }
}
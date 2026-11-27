import 'package:sqflite/sqflite.dart';

// Unlocked achievements per user. isSynced is reserved for the upload step, later.
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

  // Saves the unlocks that are not stored yet. An existing row keeps its original date.
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

  // Achievement id, then unlock time in epoch milliseconds.
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


  // Unlocks that still have to be uploaded.
  Future<Map<String, int>> getPendingUnlocks(String uid) async {
    final rows = await (await _db()).query(
      'achievements',
      columns: ['achievementId', 'unlockedAt'],
      where: 'uid = ? AND isSynced = 0',
      whereArgs: [uid],
    );
    return {
      for (final row in rows) row['achievementId'] as String: row['unlockedAt'] as int,
    };
  }

  Future<void> markSynced(String uid, String achievementId) async {
    await (await _db()).update(
      'achievements',
      {'isSynced': 1},
      where: 'uid = ? AND achievementId = ?',
      whereArgs: [uid, achievementId],
    );
  }

  // Combines the cloud unlocks with the local ones. The earliest date wins.
  // A cloud row that is not earlier leaves the local row alone, so a pending local unlock stays pending.
  Future<void> mergeRemoteUnlocks(String uid, Map<String, int> remote) async {
    final db = await _db();
    await db.transaction((txn) async {
      final rows = await txn.query(
        'achievements',
        columns: ['achievementId', 'unlockedAt'],
        where: 'uid = ?',
        whereArgs: [uid],
      );
      final local = {
        for (final row in rows) row['achievementId'] as String: row['unlockedAt'] as int,
      };

      for (final entry in remote.entries) {
        final localAt = local[entry.key];
        if (localAt == null) {
          await txn.insert('achievements', {
            'uid': uid,
            'achievementId': entry.key,
            'unlockedAt': entry.value,
            'isSynced': 1,
          });
        } else if (entry.value <= localAt) {
          await txn.update(
            'achievements',
            {'unlockedAt': entry.value, 'isSynced': 1},
            where: 'uid = ? AND achievementId = ?',
            whereArgs: [uid, entry.key],
          );
        }
      }
    });
  }

  // Deletes every unlock of one user. Only used by the developer tools.
  Future<void> deleteUnlocks(String uid) async {
    final db = await _db();
    await db.delete('achievements', where: 'uid = ?', whereArgs: [uid]);
  }

}
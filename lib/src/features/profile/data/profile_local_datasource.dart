import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../model/profile_model.dart';

/// Stores profiles on the device.
/// Own profile -> SharedPreferences, it is a single small record.
/// Friend profiles -> SQLite, many records of the same shape looked up by uid.
class ProfileLocalDatasource {
  Database? _database;

  // Key includes the uid so data from different accounts is not mixed
  String _ownProfileKey(String uid) => 'profile_own_$uid';

  Future<Database> _db() async {
    return _database ??= await openDatabase(
      '${await getDatabasesPath()}/friend_profiles.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE friend_profiles ('
          'uid TEXT PRIMARY KEY, '
          'displayName TEXT NOT NULL, '
          'photoUrl TEXT, '
          'friendCode TEXT NOT NULL, '
          'streak INTEGER NOT NULL, '
          'petLevel INTEGER NOT NULL, '
          'updatedAt INTEGER NOT NULL)',
        );
      },
    );
  }

  // Gets the stored own profile, or null if it was never saved
  Future<ProfileModel?> getOwnProfile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_ownProfileKey(uid));

    if (jsonString == null) return null;
    return ProfileModel.fromMap(jsonDecode(jsonString));
  }

  // Saves the own profile so it can be shown without connection
  Future<void> saveOwnProfile(ProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ownProfileKey(profile.uid),
      jsonEncode(profile.toMap()),
    );
  }

  // Gets the stored profile of a friend, or null if it was never saved
  Future<ProfileModel?> getFriendProfile(String uid) async {
    final rows = await (await _db()).query(
      'friend_profiles',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (rows.isEmpty) return null;
    return ProfileModel.fromMap(rows.first);
  }

  // Saves or replaces the profile of a friend with the time it was downloaded
  Future<void> saveFriendProfile(ProfileModel profile) async {
    await (await _db()).insert(
      'friend_profiles',
      {
        ...profile.toMap(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

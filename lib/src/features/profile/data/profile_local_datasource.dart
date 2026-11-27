import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../model/profile_model.dart';

/// Stores profiles on the device.
/// Own profile -> SharedPreferences, it is a single small record.
/// Friend profiles -> SQLite, many records of the same shape looked up by uid.
class ProfileLocalDatasource {
  Database? _database;

  // Keys include the uid so data from different accounts is not mixed
  String _ownProfileKey(String uid) => 'profile_own_$uid';
  String _pendingNameKey(String uid) => 'profile_pending_name_$uid';
  String _pendingPhotoKey(String uid) => 'profile_pending_photo_$uid';

  // The sync worker runs in another isolate with its own copy of the
  // preferences, so they are reloaded to see the changes it made
  Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  Future<Database> _db() async {
    return _database ??= await openDatabase(
      '${await getDatabasesPath()}/friend_profiles.db',
      version: 2,
      onCreate: (db, version) => _createFriendProfiles(db),
      // Version 2 changed petLevel for the pet and its mood.
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS friend_profiles');
        await _createFriendProfiles(db);
      },
    );
  }

  Future<void> _createFriendProfiles(Database db) {
    return db.execute(
      'CREATE TABLE friend_profiles ('
      'uid TEXT PRIMARY KEY, '
      'displayName TEXT NOT NULL, '
      'photoUrl TEXT, '
      'friendCode TEXT NOT NULL, '
      'streak INTEGER NOT NULL, '
      'petId TEXT, '
      'petMood TEXT, '
      'updatedAt INTEGER NOT NULL)',
    );
  }

  // Gets the stored own profile, or null if it was never saved
  Future<ProfileModel?> getOwnProfile(String uid) async {
    final prefs = await _prefs();
    final jsonString = prefs.getString(_ownProfileKey(uid));

    if (jsonString == null) return null;
    return ProfileModel.fromMap(jsonDecode(jsonString));
  }

  // Saves the own profile so it can be shown without connection
  Future<void> saveOwnProfile(ProfileModel profile) async {
    final prefs = await _prefs();
    await prefs.setString(
      _ownProfileKey(profile.uid),
      jsonEncode(profile.toMap()),
    );
  }

  // Gets the name changed offline that was not sent yet, or null if there is none
  Future<String?> getPendingName(String uid) async =>
      (await _prefs()).getString(_pendingNameKey(uid));

  // Keeps the new name until the sync worker sends it
  Future<void> savePendingName(String uid, String name) async =>
      (await _prefs()).setString(_pendingNameKey(uid), name);

  // Removes the pending name only if it is the one that was sent,
  // so a newer name typed during the sync is not lost
  Future<void> clearPendingName(String uid, String sentName) async {
    final prefs = await _prefs();
    if (prefs.getString(_pendingNameKey(uid)) == sentName) {
      await prefs.remove(_pendingNameKey(uid));
    }
  }

  // Indicates if the photo file still has to be uploaded
  Future<bool> hasPendingPhoto(String uid) async =>
      (await _prefs()).getBool(_pendingPhotoKey(uid)) ?? false;

  Future<void> setPendingPhoto(String uid, bool isPending) async =>
      (await _prefs()).setBool(_pendingPhotoKey(uid), isPending);

  // Gets the stored profile of a friend and when it was downloaded,
  // or null if it was never saved
  Future<({ProfileModel profile, DateTime updatedAt})?> getFriendProfile(
      String uid) async {
    final rows = await (await _db()).query(
      'friend_profiles',
      where: 'uid = ?',
      whereArgs: [uid],
    );

    if (rows.isEmpty) return null;
    return (
      profile: ProfileModel.fromMap(rows.first),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(rows.first['updatedAt'] as int),
    );
  }

  // Gets the uids of the friends whose profile is already saved
  Future<Set<String>> getSavedFriendUids() async {
    final rows = await (await _db()).query('friend_profiles', columns: ['uid']);
    return rows.map((row) => row['uid'] as String).toSet();
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

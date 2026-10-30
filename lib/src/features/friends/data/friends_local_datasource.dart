import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/friend_model.dart';
import '../model/user_profile_model.dart';

/// Stores the user's profile, last friends list and pending codes on the device
class FriendsLocalDatasource {
  // Keys include the uid so data from different accounts is not mixed
  String _profileKey(String uid) => 'friends_profile_$uid';
  String _friendsKey(String uid) => 'friends_list_$uid';
  String _lastUpdatedKey(String uid) => 'friends_last_updated_$uid';
  String _pendingCodesKey(String uid) => 'friends_pending_codes_$uid';

  // Gets the stored profile, or null if it was never saved
  Future<UserProfileModel?> getProfile(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_profileKey(uid));

    if (jsonString == null) return null;
    return UserProfileModel.fromMap(jsonDecode(jsonString));
  }

  // Saves the profile so the friend code is available offline
  Future<void> saveProfile(UserProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profileKey(profile.uid),
      jsonEncode(profile.toMap()),
    );
  }

  // Gets the last saved friends list, or null if it was never saved
  Future<List<FriendModel>?> getFriends(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_friendsKey(uid));

    if (jsonString == null) return null;

    // Convert each item into a FriendModel
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((map) => FriendModel.fromMap(map)).toList();
  }

  // Gets when the friends list was last downloaded from Firestore
  Future<DateTime?> getLastUpdated(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastUpdatedKey(uid));

    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  // Saves the friends list together with the time it was downloaded
  Future<void> saveFriends(
      String uid, List<FriendModel> friends, DateTime updatedAt) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = friends.map((f) => f.toMap()).toList();

    await prefs.setString(_friendsKey(uid), jsonEncode(jsonList));
    await prefs.setInt(_lastUpdatedKey(uid), updatedAt.millisecondsSinceEpoch);
  }

  // Gets the codes added while offline
  Future<List<String>> getPendingCodes(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingCodesKey(uid)) ?? [];
  }

  // Saves the codes that still have to be sent to Firestore
  Future<void> savePendingCodes(String uid, List<String> codes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pendingCodesKey(uid), codes);
  }
}

import 'dart:collection';

import '../model/profile_model.dart';

/// In-memory LRU cache of friend profiles by uid, with an expiration time.
/// It is the first layer: LRU (memory) -> SQLite (device) -> Firestore.
///
/// LinkedHashMap keeps the insertion order, so the first entry is always
/// the least recently used one:
/// - get: the entry is removed and inserted again, moving it to the end
/// - put: if the cache is full, the first entry (least recently used) is removed
/// Both operations are O(1).
class ProfileLruCache {
  // Max profiles kept in memory. A friends circle is small,
  // so 20 covers the friends a user opens in a session with little memory
  final int capacity;

  // After this time the profile is old (the streak or pet may have changed)
  // and it is treated as a miss, so the screen waits for Firestore
  final Duration timeToLive;

  final LinkedHashMap<String, _CacheEntry> _entries = LinkedHashMap();

  ProfileLruCache({
    this.capacity = 30,
    this.timeToLive = const Duration(minutes: 5),
  });

  // Gets a fresh profile, or null if it is not cached or it expired
  ProfileModel? get(String uid) {
    final entry = _entries.remove(uid);
    if (entry == null) return null;

    // Expired entries are dropped instead of being moved to the end
    if (DateTime.now().difference(entry.savedAt) > timeToLive) return null;

    // Insert it again so it becomes the most recently used
    _entries[uid] = entry;
    return entry.profile;
  }

  // Saves a profile as the most recently used one
  void put(ProfileModel profile) {
    _entries.remove(profile.uid);
    if (_entries.length >= capacity) {
      _entries.remove(_entries.keys.first);
    }
    _entries[profile.uid] = _CacheEntry(profile, DateTime.now());
  }
}

class _CacheEntry {
  final ProfileModel profile;
  final DateTime savedAt;

  _CacheEntry(this.profile, this.savedAt);
}

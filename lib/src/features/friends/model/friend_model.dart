// Possible results when adding a friend by code
enum AddFriendResult { added, notFound, ownCode }

/// Model that represents a friend shown in the friends list
class FriendModel {
  final String uid;
  final String displayName;
  final int streak;

  // Pet chosen by the friend ("sprout") and its mood ("HAPPY"), null if none yet
  final String? petId;
  final String? petMood;

  FriendModel({
    required this.uid,
    required this.displayName,
    required this.streak,
    this.petId,
    this.petMood,
  });

  // Creates a FriendModel from locally stored data
  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? '',
      streak: map['streak'] as int? ?? 0,
      petId: map['petId'] as String?,
      petMood: map['petMood'] as String?,
    );
  }

  // Converts the model into a Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'streak': streak,
      'petId': petId,
      'petMood': petMood,
    };
  }

  // Creates a FriendModel from the friend's profile (users/{uid})
  // and progress (users/{uid}/progress/current) documents
  factory FriendModel.fromFirestore({
    required String uid,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> progress,
  }) {
    return FriendModel(
      uid: uid,
      displayName: profile['displayName'] as String? ?? '',

      streak: (progress['streak'] as num?)?.toInt() ?? 0,
      // Saved in users/{uid} by the backend when the pet syncs
      petId: profile['activePetId'] as String?,
      petMood: profile['petMood'] as String?,
    );
  }
}

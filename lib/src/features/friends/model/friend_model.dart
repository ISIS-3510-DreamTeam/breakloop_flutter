// Possible results when adding a friend by code
enum AddFriendResult { added, notFound, ownCode }

/// Model that represents a friend shown in the friends list
class FriendModel {
  final String uid;
  final String displayName;
  final int streak;
  final int petLevel;

  FriendModel({
    required this.uid,
    required this.displayName,
    required this.streak,
    required this.petLevel,
  });

  // Creates a FriendModel from locally stored data
  factory FriendModel.fromMap(Map<String, dynamic> map) {
    return FriendModel(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? '',
      streak: map['streak'] as int? ?? 0,
      petLevel: map['petLevel'] as int? ?? 1,
    );
  }

  // Converts the model into a Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'streak': streak,
      'petLevel': petLevel,
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
      petLevel: (progress['petLevel'] as num?)?.toInt() ?? 1,
    );
  }
}

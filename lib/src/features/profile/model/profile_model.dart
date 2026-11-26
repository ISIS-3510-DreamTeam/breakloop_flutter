/// Profile shown in the profile screens (own profile and friend profile).
/// Built from users/{uid} and users/{uid}/progress/current
class ProfileModel {
  final String uid;
  final String displayName;

  // Download URL of the profile photo, null if the user has no photo
  final String? photoUrl;

  // Code other users type to add this user as a friend
  final String friendCode;

  final int streak;
  final int petLevel;

  ProfileModel({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.friendCode,
    required this.streak,
    required this.petLevel,
  });

  // Creates a ProfileModel from the profile and progress documents
  factory ProfileModel.fromFirestore({
    required String uid,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> progress,
  }) {
    return ProfileModel(
      uid: uid,
      displayName: profile['displayName'] as String? ?? '',
      photoUrl: profile['photoUrl'] as String?,
      friendCode: profile['friendCode'] as String? ?? '',
      streak: (progress['streak'] as num?)?.toInt() ?? 0,
      petLevel: (progress['petLevel'] as num?)?.toInt() ?? 1,
    );
  }

  // Creates a new profile while keeping the values that were not changed
  ProfileModel copyWith({String? displayName, String? photoUrl}) {
    return ProfileModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      friendCode: friendCode,
      streak: streak,
      petLevel: petLevel,
    );
  }
}

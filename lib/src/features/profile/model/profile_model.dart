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

  // Pet chosen by the user ("sprout") and its mood ("HAPPY"), null if none yet
  final String? petId;
  final String? petMood;

  ProfileModel({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.friendCode,
    required this.streak,
    this.petId,
    this.petMood,
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
      // Saved in users/{uid} by the backend when the pet syncs
      petId: profile['activePetId'] as String?,
      petMood: profile['petMood'] as String?,
    );
  }

  // Creates a ProfileModel from locally stored data
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      uid: map['uid'] as String,
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      friendCode: map['friendCode'] as String? ?? '',
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
      'photoUrl': photoUrl,
      'friendCode': friendCode,
      'streak': streak,
      'petId': petId,
      'petMood': petMood,
    };
  }

  // Creates a new profile while keeping the values that were not changed
  ProfileModel copyWith({String? displayName, String? photoUrl}) {
    return ProfileModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      friendCode: friendCode,
      streak: streak,
      petId: petId,
      petMood: petMood,
    );
  }
}

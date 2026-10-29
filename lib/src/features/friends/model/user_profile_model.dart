import 'package:cloud_firestore/cloud_firestore.dart';

/// Public profile of a user, stored in users/{uid}
class UserProfileModel {
  final String uid;
  final String email;
  final String displayName;

  // Short code other users type to add this user as a friend
  final String friendCode;

  UserProfileModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.friendCode,
  });

  // Creates a UserProfileModel from Firestore data
  factory UserProfileModel.fromFirestore(
      Map<String, dynamic> data, String docId) {
    return UserProfileModel(
      // The Firestore document ID is the Firebase Auth uid
      uid: docId,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      friendCode: data['friendCode'] as String? ?? '',
    );
  }

  // Converts the model into a format that can be sent to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'friendCode': friendCode,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// App the user wants to use more intentionally
class FlaggedApp {
  final String packageName;
  //Null means the app has no daily limit
  final int? dailyLimitMin;
  //Milliseconds since epoch
  final int flaggedAt;

  const FlaggedApp({
    required this.packageName,
    required this.dailyLimitMin,
    required this.flaggedAt,
  });

  // Creates a FlaggedApp from a row of the local database
  factory FlaggedApp.fromMap(Map<String, Object?> map) {
    return FlaggedApp(
      packageName: map['packageName'] as String,
      dailyLimitMin: map['dailyLimitMin'] as int?,
      flaggedAt: map['flaggedAt'] as int,
    );
  }

  // Converts the model into a format that can be sent to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'packageName': packageName,
      'dailyLimitMin': dailyLimitMin,
      'flaggedAt': Timestamp.fromMillisecondsSinceEpoch(flaggedAt),
    };
  }
}

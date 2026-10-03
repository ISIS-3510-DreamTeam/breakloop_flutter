import 'package:cloud_firestore/cloud_firestore.dart';

// Types of focus sessions available in the app
enum SessionType { pomodoro, deepWork, shortBreak }

// Possible states of a focus session
enum SessionStatus { completed, abandoned, inProgress }

/// Model that represents a focus session
class FocusSessionModel {
  final String sessionId;
  final String userId;
  final DateTime startedAt;
  final int durationSeconds;
  final SessionType sessionType;
  final SessionStatus sessionStatus;
  final int earnedXp;
  final bool isSynced;

  FocusSessionModel({
    required this.sessionId,
    required this.userId,
    required this.startedAt,
    required this.durationSeconds,
    required this.sessionType,
    required this.sessionStatus,
    required this.earnedXp,
    this.isSynced = false,
  });

  /// Creates a FocusSessionModel from locally stored data
  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    return FocusSessionModel(
      // Get the session ID from the stored data.
      sessionId: map['sessionId'] as String,

      // Get the user ID or use an empty string if it is missing
      userId: map['userId'] as String? ?? '',

      // Convert the stored timestamp into a DateTime
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        map['startedAt'] as int,
      ),

      // Get the duration of the session
      durationSeconds: map['durationSeconds'] as int,

      // Convert the stored text into a SessionType
      sessionType: SessionType.values.firstWhere(
        (e) => e.name == map['sessionType'],
        orElse: () => SessionType.pomodoro,
      ),

      // Convert the stored text into a SessionStatus
      sessionStatus: SessionStatus.values.firstWhere(
        (e) => e.name == map['sessionStatus'],
        orElse: () => SessionStatus.completed,
      ),

      // Get the XP earned during the session
      earnedXp: map['earnedXp'] as int? ?? 0,

      // Get the synchronization status.
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  // Converts the model into a Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,

      // Store the date as milliseconds because it is easier to save locally
      'startedAt': startedAt.millisecondsSinceEpoch,

      'durationSeconds': durationSeconds,
      'sessionType': sessionType.name,
      'sessionStatus': sessionStatus.name,
      'earnedXp': earnedXp,
      'isSynced': isSynced,
    };
  }

  // Creates a FocusSessionModel from Firestore data
  factory FocusSessionModel.fromFirestore(
      Map<String, dynamic> data, String docId) {
    DateTime parsedDate;

    // Firestore normally stores dates as Timestamp.
    if (data['startedAt'] is Timestamp) {
      parsedDate = (data['startedAt'] as Timestamp).toDate();
    }

    // Also support timestamps stored as milliseconds
    else if (data['startedAt'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(
        data['startedAt'] as int,
      );
    }

    // uuse the current date if no valid date is available
    else {
      parsedDate = DateTime.now();
    }

    return FocusSessionModel(
      // The Firestore document ID is used as the session id
      sessionId: docId,

      userId: data['userId'] as String? ?? '',
      startedAt: parsedDate,

      // Convert the value to int in case Firestore returns another number type
      durationSeconds:
          (data['durationSeconds'] as num?)?.toInt() ?? 0,

      // Convert the stored text into a SessionType.
      sessionType: SessionType.values.firstWhere(
        (e) => e.name == data['sessionType'],
        orElse: () => SessionType.pomodoro,
      ),

      // Convert the stored text into a SessionStatus
      sessionStatus: SessionStatus.values.firstWhere(
        (e) => e.name == data['sessionStatus'],
        orElse: () => SessionStatus.completed,
      ),

      earnedXp: (data['earnedXp'] as num?)?.toInt() ?? 0,

      // Data coming from Firestore is already synchronized
      isSynced: true,
    );
  }

  // Converts the model into a format that can be sent to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'userId': userId,

      // Firestore uses Timestamp for dates.
      'startedAt': Timestamp.fromDate(startedAt),

      'durationSeconds': durationSeconds,
      'sessionType': sessionType.name,
      'sessionStatus': sessionStatus.name,
      'earnedXp': earnedXp,
    };
  }

  // Creates a new copy of the session with selected changes
  FocusSessionModel copyWith({
    String? sessionId,
    String? userId,
    DateTime? startedAt,
    int? durationSeconds,
    SessionType? sessionType,
    SessionStatus? sessionStatus,
    int? earnedXp,
    bool? isSynced,
  }) {
    return FocusSessionModel(
      // Keep the old value if no new value was provided
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      startedAt: startedAt ?? this.startedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sessionType: sessionType ?? this.sessionType,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      earnedXp: earnedXp ?? this.earnedXp,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
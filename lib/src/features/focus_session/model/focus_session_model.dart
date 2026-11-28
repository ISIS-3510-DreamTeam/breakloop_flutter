
import 'package:cloud_firestore/cloud_firestore.dart';

// Tipo de sesión disponible en la app
enum SessionType { focus }

// Estados posibles de la sesión
enum SessionStatus { active, paused, completed, abandoned }

/// Model representing a focus session
class FocusSessionModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final int duration;
  final SessionType sessionType;
  final SessionStatus sessionStatus;
  final int xpEarned;
  final bool isSynced;

  // Information required for Focus Recovery
  final String focusGoal;
  final DateTime? pausedAt;
  final int totalPausedSeconds;
  final int elapsedSeconds;
  final int remainingSeconds;
  final DateTime? lastUpdatedAt;

  FocusSessionModel({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.duration,
    required this.sessionType,
    required this.sessionStatus,
    required this.xpEarned,
    this.isSynced = false,
    this.focusGoal = '',
    this.pausedAt,
    this.totalPausedSeconds = 0,
    this.elapsedSeconds = 0,
    this.remainingSeconds = 0,
    this.lastUpdatedAt,
  });

  // Converts stored dates into DateTime
  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is DateTime) return value;
    return null;
  }

  /// Creates a model from locally stored data
  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    return FocusSessionModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      startTime: _parseDate(map['startTime']) ?? DateTime.now(),
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      sessionType: SessionType.values.firstWhere(
        (e) => e.name.toUpperCase() ==
            (map['type'] ?? map['sessionType']).toString().toUpperCase(),
        orElse: () => SessionType.focus,
      ),
      sessionStatus: SessionStatus.values.firstWhere(
        (e) => e.name.toUpperCase() ==
            (map['status'] ?? map['sessionStatus']).toString().toUpperCase(),
        orElse: () => SessionStatus.completed,
      ),
      xpEarned: (map['xpEarned'] as num?)?.toInt() ??
          (map['earnedXp'] as num?)?.toInt() ?? 0,
      isSynced: map['isSynced'] as bool? ?? false,
      focusGoal: map['focusGoal'] as String? ?? '',
      pausedAt: _parseDate(map['pausedAt']),
      totalPausedSeconds:
          (map['totalPausedSeconds'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (map['elapsedSeconds'] as num?)?.toInt() ?? 0,
      remainingSeconds: (map['remainingSeconds'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: _parseDate(map['lastUpdatedAt']),
    );
  }

  // Converts the model into a local Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startTime': startTime.millisecondsSinceEpoch,
      'duration': duration,
      'type': sessionType.name.toUpperCase(),
      'status': sessionStatus.name.toUpperCase(),
      'xpEarned': xpEarned,
      'isSynced': isSynced,
      'focusGoal': focusGoal,
      'pausedAt': pausedAt?.millisecondsSinceEpoch,
      'totalPausedSeconds': totalPausedSeconds,
      'elapsedSeconds': elapsedSeconds,
      'remainingSeconds': remainingSeconds,
      'lastUpdatedAt': lastUpdatedAt?.millisecondsSinceEpoch,
    };
  }

  /// Creates a model from Firestore data
  factory FocusSessionModel.fromFirestore(
      Map<String, dynamic> data, String docId) {
    return FocusSessionModel(
      id: docId,
      userId: data['userId'] as String? ?? '',
      startTime: _parseDate(data['startTime']) ?? DateTime.now(),
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      sessionType: SessionType.values.firstWhere(
        (e) => e.name.toUpperCase() ==
            (data['type'] ?? '').toString().toUpperCase(),
        orElse: () => SessionType.focus,
      ),
      sessionStatus: SessionStatus.values.firstWhere(
        (e) => e.name.toUpperCase() ==
            (data['status'] ?? '').toString().toUpperCase(),
        orElse: () => SessionStatus.completed,
      ),
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
      isSynced: true,
      focusGoal: data['focusGoal'] as String? ?? '',
      pausedAt: _parseDate(data['pausedAt']),
      totalPausedSeconds:
          (data['totalPausedSeconds'] as num?)?.toInt() ?? 0,
      elapsedSeconds: (data['elapsedSeconds'] as num?)?.toInt() ?? 0,
      remainingSeconds: (data['remainingSeconds'] as num?)?.toInt() ?? 0,
      lastUpdatedAt: _parseDate(data['lastUpdatedAt']),
    );
  }

  // Converts the model into a Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'duration': duration,
      'type': sessionType.name.toUpperCase(),
      'status': sessionStatus.name.toUpperCase(),
      'xpEarned': xpEarned,
      'focusGoal': focusGoal,
      'pausedAt': pausedAt == null
          ? null
          : Timestamp.fromDate(pausedAt!),
      'totalPausedSeconds': totalPausedSeconds,
      'elapsedSeconds': elapsedSeconds,
      'remainingSeconds': remainingSeconds,
      'lastUpdatedAt': lastUpdatedAt == null
          ? null
          : Timestamp.fromDate(lastUpdatedAt!),
    };
  }

  // Creates a copy with selected changes
  FocusSessionModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    int? duration,
    SessionType? sessionType,
    SessionStatus? sessionStatus,
    int? xpEarned,
    bool? isSynced,
    String? focusGoal,
    DateTime? pausedAt,
    bool clearPausedAt = false,
    int? totalPausedSeconds,
    int? elapsedSeconds,
    int? remainingSeconds,
    DateTime? lastUpdatedAt,
    bool clearLastUpdatedAt = false,
  }) {
    return FocusSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      sessionType: sessionType ?? this.sessionType,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      xpEarned: xpEarned ?? this.xpEarned,
      isSynced: isSynced ?? this.isSynced,
      focusGoal: focusGoal ?? this.focusGoal,
      pausedAt: clearPausedAt ? null : pausedAt ?? this.pausedAt,
      totalPausedSeconds:
          totalPausedSeconds ?? this.totalPausedSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      lastUpdatedAt: clearLastUpdatedAt
          ? null
          : lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}

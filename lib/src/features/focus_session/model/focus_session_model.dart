import 'package:cloud_firestore/cloud_firestore.dart';

// Tipo de sesión disponible en la app
enum SessionType { focus }

// Estados posibles de la sesión
enum SessionStatus { completed, abandoned }

/// Modelo que representa una sesión de enfoque
class FocusSessionModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final int duration;
  final SessionType sessionType;
  final SessionStatus sessionStatus;
  final int xpEarned;
  final bool isSynced;

  FocusSessionModel({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.duration,
    required this.sessionType,
    required this.sessionStatus,
    required this.xpEarned,
    this.isSynced = false,
  });

  /// Crea un FocusSessionModel desde datos almacenados localmente
  factory FocusSessionModel.fromMap(Map<String, dynamic> map) {
    return FocusSessionModel(
      id: map['id'] as String? ?? map['sessionId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      startTime: map['startTime'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int)
          : map['startTime'] is Timestamp
              ? (map['startTime'] as Timestamp).toDate()
              : DateTime.now(),
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      sessionType: SessionType.values.firstWhere(
        (e) => e.name.toUpperCase() == (map['type'] ?? map['sessionType']).toString().toUpperCase(),
        orElse: () => SessionType.focus,
      ),
      sessionStatus: SessionStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (map['status'] ?? map['sessionStatus']).toString().toUpperCase(),
        orElse: () => SessionStatus.completed,
      ),
      xpEarned: (map['xpEarned'] as num?)?.toInt() ?? (map['earnedXp'] as num?)?.toInt() ?? 0,
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }

  // Convierte el modelo a un Map para almacenamiento local
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
    };
  }

  // Crea un FocusSessionModel desde datos de Firestore
  factory FocusSessionModel.fromFirestore(
      Map<String, dynamic> data, String docId) {
    DateTime parsedDate;

    if (data['startTime'] is Timestamp) {
      parsedDate = (data['startTime'] as Timestamp).toDate();
    } else if (data['startTime'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(data['startTime'] as int);
    } else {
      parsedDate = DateTime.now();
    }

    return FocusSessionModel(
      id: docId,
      userId: data['userId'] as String? ?? '',
      startTime: parsedDate,
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      sessionType: SessionType.values.firstWhere(
        (e) => e.name.toUpperCase() == (data['type'] ?? '').toString().toUpperCase(),
        orElse: () => SessionType.focus,
      ),
      sessionStatus: SessionStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (data['status'] ?? '').toString().toUpperCase(),
        orElse: () => SessionStatus.completed,
      ),
      xpEarned: (data['xpEarned'] as num?)?.toInt() ?? 0,
      isSynced: true,
    );
  }

  // Convierte el modelo a un formato para enviar a Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'duration': duration,
      'type': sessionType.name.toUpperCase(),
      'status': sessionStatus.name.toUpperCase(),
      'xpEarned': xpEarned,
    };
  }

  // Crea una copia con los cambios seleccionados
  FocusSessionModel copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    int? duration,
    SessionType? sessionType,
    SessionStatus? sessionStatus,
    int? xpEarned,
    bool? isSynced,
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
    );
  }
}
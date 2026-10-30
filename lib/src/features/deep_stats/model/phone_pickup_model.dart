import 'package:cloud_firestore/cloud_firestore.dart';

class PhonePickupModel {
  final String pickupId;
  final String userId;
  final DateTime timestamp;
  final bool isSynced;
  
  final int hourOfDay;   
  final int dayOfWeek;      
  final bool isIntentional;  

  const PhonePickupModel({
    required this.pickupId,
    required this.userId,
    required this.timestamp,
    this.isSynced = false,
    required this.hourOfDay,
    required this.dayOfWeek,
    required this.isIntentional,
  });

  // Convert to local map
  Map<String, dynamic> toMap() {
    return {
      'pickupId': pickupId,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
      'isSynced': isSynced,
      'hourOfDay': hourOfDay,
      'dayOfWeek': dayOfWeek,
      'isIntentional': isIntentional,
    };
  }

  // Create from local map
  factory PhonePickupModel.fromMap(Map<String, dynamic> map) {
    return PhonePickupModel(
      pickupId: map['pickupId'] as String,
      userId: map['userId'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: map['isSynced'] as bool? ?? false,
      hourOfDay: map['hourOfDay'] as int? ?? DateTime.parse(map['timestamp'] as String).hour,
      dayOfWeek: map['dayOfWeek'] as int? ?? DateTime.parse(map['timestamp'] as String).weekday,
      isIntentional: map['isIntentional'] as bool? ?? true,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'pickupId': pickupId,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'hourOfDay': hourOfDay,
      'dayOfWeek': dayOfWeek,
      'isIntentional': isIntentional,
    };
  }

// Create a model from a Firestore document (Versión segura con casting)
  factory PhonePickupModel.fromFirestore(
    DocumentSnapshot document,
  ) {
    final data = document.data() as Map<String, dynamic>?;

    if (data == null) {
      throw StateError('Phone pickup document has no data.');
    }

    final timestampValue = data['timestamp'];
    final parsedTimestamp = timestampValue is Timestamp
        ? timestampValue.toDate()
        : DateTime.parse(timestampValue as String);

    return PhonePickupModel(
      pickupId: document.id,
      userId: data['userId'] as String? ?? '',
      timestamp: parsedTimestamp,
      isSynced: true,
      hourOfDay: data['hourOfDay'] as int? ?? parsedTimestamp.hour,
      dayOfWeek: data['dayOfWeek'] as int? ?? parsedTimestamp.weekday,
      isIntentional: data['isIntentional'] as bool? ?? true,
    );
  }

  PhonePickupModel copyWith({
    String? pickupId,
    String? userId,
    DateTime? timestamp,
    bool? isSynced,
    int? hourOfDay,
    int? dayOfWeek,
    bool? isIntentional,
  }) {
    return PhonePickupModel(
      pickupId: pickupId ?? this.pickupId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      hourOfDay: hourOfDay ?? this.hourOfDay,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isIntentional: isIntentional ?? this.isIntentional,
    );
  }
}
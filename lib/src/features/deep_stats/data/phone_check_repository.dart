import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/phone_pickup_model.dart';
import 'phone_pickup_remote_datasource.dart';

/// Repository responsible for local storage and Firebase synchronization.
class PhoneCheckRepository {
  static const String _keyPickups = 'phone_check_timestamps';
  static const String _keyPickupModels = 'phone_pickup_records';

  final PhonePickupRemoteDatasource _remoteDatasource;
  final FirebaseAuth _auth;

  bool _isSyncing = false;

  PhoneCheckRepository({
    PhonePickupRemoteDatasource? remoteDatasource,
    FirebaseAuth? auth,
  })  : _remoteDatasource =
            remoteDatasource ?? PhonePickupRemoteDatasource(),
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  /// Reads local records and migrates legacy formats if needed.
  Future<List<PhonePickupModel>> _getLocalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRecords = prefs.getStringList(_keyPickupModels);

    if (storedRecords != null) {
      return storedRecords
          .map(
            (record) => PhonePickupModel.fromMap(
              jsonDecode(record) as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    // Migrate old format
    final oldRecords = prefs.getStringList(_keyPickups) ?? [];
    final migratedRecords = <PhonePickupModel>[];

    for (var i = 0; i < oldRecords.length; i++) {
      try {
        final timestamp = DateTime.parse(oldRecords[i]);
        migratedRecords.add(
          PhonePickupModel(
            pickupId: 'legacy_${timestamp.microsecondsSinceEpoch}_$i',
            userId: '',
            timestamp: timestamp,
            isSynced: false,
            hourOfDay: timestamp.hour,
            dayOfWeek: timestamp.weekday,
            isIntentional: true,
          ),
        );
      } on FormatException {
        // Ignore malformed
      }
    }

    final saved = await prefs.setStringList(
      _keyPickupModels,
      migratedRecords.map((record) => jsonEncode(record.toMap())).toList(),
    );

    if (saved) {
      await prefs.remove(_keyPickups);
    }

    return migratedRecords;
  }

  /// Saves a new pickup locally as pending.
  Future<void> savePickup({
    required DateTime timestamp,
    bool isIntentional = false,
  }) async {
    final records = await _getLocalRecords();

    final pickup = PhonePickupModel(
      pickupId: 'pickup_${timestamp.microsecondsSinceEpoch}',
      userId: _currentUserId ?? '',
      timestamp: timestamp,
      isSynced: false,
      hourOfDay: timestamp.hour,
      dayOfWeek: timestamp.weekday,
      isIntentional: isIntentional,
    );

    records.add(pickup);
    await _saveLocalRecords(records);
  }

  /// Actualiza el estado de intencionalidad del último registro guardado.
  Future<void> updateLastPickupIntentionality(bool isIntentional) async {
    final records = await _getLocalRecords();
    if (records.isEmpty) return;

    // Actualizamos el último elemento guardado con su valor real evaluado a los 5s
    final lastIndex = records.length - 1;
    records[lastIndex] = records[lastIndex].copyWith(
      isIntentional: isIntentional,
    );

    await _saveLocalRecords(records);
  }

  Future<void> _saveLocalRecords(List<PhonePickupModel> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _keyPickupModels,
      records.map((record) => jsonEncode(record.toMap())).toList(),
    );
  }

  Future<List<DateTime>> getPickups() async {
    final records = await _getLocalRecords();
    return records.map((record) => record.timestamp).toList();
  }

  Future<List<DateTime>> getTodayPickups() async {
    final allPickups = await getPickups();
    final now = DateTime.now();

    return allPickups.where((pickup) {
      return pickup.year == now.year &&
          pickup.month == now.month &&
          pickup.day == now.day;
    }).toList();
  }

  Future<List<PhonePickupModel>> getUnsyncedPickups() async {
    final records = await _getLocalRecords();
    return records.where((record) => !record.isSynced).toList();
  }

  /// Uploads pending records safely without race conditions.
  Future<void> syncUnsyncedPickups() async {
    if (_isSyncing) return;
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    _isSyncing = true;

    try {
      final pendingRecords = await getUnsyncedPickups();
      if (pendingRecords.isEmpty) return;

      final records = await _getLocalRecords();
      bool changesMade = false;

      for (final pending in pendingRecords) {
        if (pending.userId.isNotEmpty && pending.userId != userId) {
          continue;
        }

        final pickup = pending.copyWith(userId: userId);

        try {
          await _remoteDatasource.savePickup(pickup);

          final index = records.indexWhere(
            (record) => record.pickupId == pickup.pickupId,
          );

          if (index != -1) {
            records[index] = pickup.copyWith(isSynced: true);
            changesMade = true;
          }
        } catch (_) {
          continue;
        }
      }

      if (changesMade) {
        await _saveLocalRecords(records);
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> clearOldPickups() async {
    final records = await _getLocalRecords();
    final now = DateTime.now();

    final retainedRecords = records.where((record) {
      final isToday = record.timestamp.year == now.year &&
          record.timestamp.month == now.month &&
          record.timestamp.day == now.day;

      return isToday || !record.isSynced;
    }).toList();

    await _saveLocalRecords(retainedRecords);
  }

  /// Verifica si hay al menos 10 pickups pendientes y sube un lote (batch) a Firebase
  Future<void> checkAndSyncBatch() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    final pendingRecords = await getUnsyncedPickups();

    // Solo subimos si se acumularon al menos 10 pickups pendientes
    if (pendingRecords.length < 10) return;

    // Tomamos exactamente los primeros 10
    final batchRecords = pendingRecords.take(10).toList();

    int totalPickups = batchRecords.length;
    int intentionalCount = batchRecords.where((r) => r.isIntentional).length;
    double intentionalPercentage = (intentionalCount / totalPickups) * 100;
    double nonIntentionalPercentage = 100.0 - intentionalPercentage;

    final batchData = {
      'batchId': 'batch_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': Timestamp.now(),
      'totalPickups': totalPickups,
      'intentionalCount': intentionalCount,
      'nonIntentionalCount': totalPickups - intentionalCount,
      'intentionalPercentage': intentionalPercentage,
      'nonIntentionalPercentage': nonIntentionalPercentage,
      'pickupsList': batchRecords.map((r) => r.toFirestore()).toList(),
    };

    try {
      await _remoteDatasource.saveBatchSummary(userId, batchData);

      final records = await _getLocalRecords();
      final batchIdsToSync = batchRecords.map((r) => r.pickupId).toSet();

      for (int i = 0; i < records.length; i++) {
        if (batchIdsToSync.contains(records[i].pickupId)) {
          records[i] = records[i].copyWith(isSynced: true);
        }
      }

      await _saveLocalRecords(records);
    } catch (_) {
      // Si falla la red, se mantiene local para reintentar luego
    }
  }
}
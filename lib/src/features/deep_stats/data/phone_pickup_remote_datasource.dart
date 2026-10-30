
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/phone_pickup_model.dart';

class PhonePickupRemoteDatasource {
  final FirebaseFirestore _firestore;

  PhonePickupRemoteDatasource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Save a phone pickup in Firestore.
  Future<void> savePickup(PhonePickupModel pickup) async {
    if (pickup.userId.isEmpty) {
      throw ArgumentError('The user ID cannot be empty.');
    }

    await _firestore
        .collection('users')
        .doc(pickup.userId)
        .collection('phone_pickups')
        .doc(pickup.pickupId)
        .set(pickup.toFirestore());
  }

  // Fetch all phone pickups for a user.
  Future<List<PhonePickupModel>> fetchRemotePickups(
    String userId,
  ) async {
    if (userId.isEmpty) {
      throw ArgumentError('The user ID cannot be empty.');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('phone_pickups')
        .get();

    return snapshot.docs
        .map((document) => PhonePickupModel.fromFirestore(document))
        .toList();
  }

  // Save a summarized metrics block in Firestore for Business Questions.
  Future<void> saveMinuteSummary(String userId, Map<String, dynamic> summaryData) async {
    if (userId.isEmpty) {
      throw ArgumentError('The user ID cannot be empty.');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('phone_summaries') // Colección especial para reportes y analítica
        .doc(summaryData['summaryId'] as String)
        .set(summaryData);
  }

  // Guarda un lote de 10 pickups con sus estadísticas y su lista interna
  Future<void> saveBatchSummary(String userId, Map<String, dynamic> batchData) async {
    if (userId.isEmpty) {
      throw ArgumentError('The user ID cannot be empty.');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('phone_batches') // Colección de lotes de 10
        .doc(batchData['batchId'] as String)
        .set(batchData);
  }
}

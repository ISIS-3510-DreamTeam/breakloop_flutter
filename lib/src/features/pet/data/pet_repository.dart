
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';

import '../model/local_pet_state.dart';
import '../model/pet_dto.dart';
import '../model/pet_mood.dart';
import '../model/pet_state_request.dart';
import 'pet_api.dart';
import 'pet_image_storage.dart';
import 'pet_local_store.dart';
import 'pet_sync_worker.dart';

class PetRepository {
  PetRepository({
    PetLocalStore? localStore,
    PetImageStorage? imageStorage,
    PetApi? api,
  })  : _localStore = localStore ?? PetLocalStore(),
        _imageStorage = imageStorage ?? PetImageStorage(),
        _api = api ?? PetApi();

  final PetLocalStore _localStore;
  final PetImageStorage _imageStorage;
  final PetApi _api;

  // Lo que consume el ViewModel
  Stream<LocalPetState> observeState() => _localStore.state;

  Future<Uint8List?> getImageBytes(PetMood mood) => _imageStorage.readImageBytes(mood);

  // called from the ui
  void startListeningToBackground() =>
      PetSyncWorker.listenForUiRefresh(_localStore.notifyChanged);

  void notifyExternalChange() => _localStore.notifyChanged();

  // Save the choice and let the worker apply it when available
  Future<void> changePet(String petId) async {
    await _localStore.setPendingPet(petId);
    await PetSyncWorker.schedule();
  }

  Future<void> updateMood(PetMood mood) async {
    if (await _localStore.setMood(mood)) {
      await PetSyncWorker.schedule();
    }
  }

  //Re-Synchronize
  Future<void> scheduleSync() => PetSyncWorker.schedule();

  //Catalog from the server if possible; else the last saved copy
  Future<List<PetDto>> getCatalog() async {
    try {
      final pets = await _api.getPets();
      await _localStore.saveCatalog(jsonEncode([for (final p in pets) p.toJson()]));
      return pets;
    } catch (_) {
      final saved = await _localStore.getCatalog();
      if (saved == null) return const [];
      final list = jsonDecode(saved) as List<dynamic>;
      return [for (final e in list) PetDto.fromJson(e as Map<String, dynamic>)];
    }
  }

  //called by petworker, which runs only when there is an internet connection
  Future<void> syncWithServer() async {
    // 1. apply the pending pet change
    final pendingId = (await _localStore.getState()).pendingPetId;
    if (pendingId != null) {
      await _downloadPet(pendingId);
      await _localStore.finishPetChange(pendingId);
    }

    // 2. Send pet and current mood to the backend (if outdated)
    final state = await _localStore.getState();
    final petId = state.currentPetId;
    if (petId == null || state.synced) return;

    final user = await FirebaseAuth.instance.authStateChanges().first;
    final uid = user?.uid;
    if (uid == null) return;

    final response = await _api.updatePetState(
      uid,
      PetStateRequest(
        activePetId: petId,
        petMood: state.mood.apiName,
        petUpdatedAt: state.updatedAt,
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Could not sync pet. HTTP ${response.statusCode}');
    }
    await _localStore.markSynced(state.updatedAt);
  }

  Future<void> _downloadPet(String petId) async {
    final catalog = await getCatalog();
    final pet = catalog.firstWhere((p) => p.id == petId);

    // Download to a temporary folder and exchange with on-device files
    await _imageStorage.startDownload();
    for (final entry in pet.images.entries) {
      final bytes = await _api.downloadFile(entry.value);
      await _imageStorage.saveDownloadedImage(entry.key, bytes);
    }
    await _imageStorage.finishDownload();
  }

  void dispose() {
    PetSyncWorker.stopListeningForUiRefresh();
    _localStore.dispose();
    _api.dispose();
  }
}
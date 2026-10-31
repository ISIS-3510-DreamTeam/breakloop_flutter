
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/local_pet_state.dart';
import '../model/pet_mood.dart';

// Save the pet state. We use sharedPreferencesAsync in substitution for threading.
class PetLocalStore {
  PetLocalStore({SharedPreferencesAsync? prefs}) : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;
  final _changes = StreamController<void>.broadcast();

  static const _currentPetKey = 'pet.current_pet_id';
  static const _pendingPetKey = 'pet.pending_pet_id';
  static const _moodKey = 'pet.mood';
  static const _syncedKey = 'pet.synced';
  static const _updatedAtKey = 'pet.updated_at';
  static const _catalogKey = 'pet.catalog_json';

  // Emits the current state and then a new one after each change
  Stream<LocalPetState> get state async* {
    yield await getState();
    yield* _changes.stream.asyncMap((_) => getState());
  }

  // called after writing or when the worker notifies it wrote into another isolate
  void notifyChanged() => _changes.add(null);

  Future<LocalPetState> getState() async => LocalPetState(
    currentPetId: await _prefs.getString(_currentPetKey),
    pendingPetId: await _prefs.getString(_pendingPetKey),
    mood: PetMood.fromApiName(await _prefs.getString(_moodKey)),
    synced: await _prefs.getBool(_syncedKey) ?? true,
    updatedAt: await _prefs.getInt(_updatedAtKey) ?? 0,
  );

  // Overwrites any previous pending election (just the last one).
  Future<void> setPendingPet(String petId) async {
    if (await _prefs.getString(_currentPetKey) == petId) {
      await _prefs.remove(_pendingPetKey); // return to current pet
    } else {
      await _prefs.setString(_pendingPetKey, petId);
    }
    notifyChanged();
  }

  // Called when the images of the new pet are already on disc
  Future<void> finishPetChange(String petId) async {
    await _prefs.setString(_currentPetKey, petId);
    // If the user picked another one during download, pending is conserved.
    if (await _prefs.getString(_pendingPetKey) == petId) {
      await _prefs.remove(_pendingPetKey);
    }
    await _prefs.setBool(_syncedKey, false);
    await _prefs.setInt(_updatedAtKey, DateTime.now().millisecondsSinceEpoch);
    notifyChanged();
  }

  // Returns true only if the mood is what actually changed
  Future<bool> setMood(PetMood mood) async {
    if (await _prefs.getString(_moodKey) == mood.apiName) return false;
    await _prefs.setString(_moodKey, mood.apiName);
    await _prefs.setBool(_syncedKey, false);
    await _prefs.setInt(_updatedAtKey, DateTime.now().millisecondsSinceEpoch);
    notifyChanged();
    return true;
  }

  // Marks as synchronized if nothing changed while uploading
  Future<void> markSynced(int sentUpdatedAt) async {
    if ((await _prefs.getInt(_updatedAtKey) ?? 0) == sentUpdatedAt) {
      await _prefs.setBool(_syncedKey, true);
      notifyChanged();
    }
  }

  Future<void> saveCatalog(String json) => _prefs.setString(_catalogKey, json);

  Future<String?> getCatalog() => _prefs.getString(_catalogKey);

  void dispose() => _changes.close();
}
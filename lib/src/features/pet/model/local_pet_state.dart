

import 'pet_mood.dart';

class LocalPetState {
  const LocalPetState({
    this.currentPetId,
    this.pendingPetId,
    this.mood = PetMood.sad,
    this.synced = true,
    this.updatedAt = 0,
  });

  final String? currentPetId; // pet whose images are on the device
  final String? pendingPetId; // chosen pet, but not downloaded yet
  final PetMood mood;
  final bool synced; // false = server doesn't know yet the las pet/mood
  final int updatedAt; // last update time
}
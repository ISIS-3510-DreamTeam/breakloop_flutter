
import 'pet_mood.dart';

class CalculatePetMoodUseCase {
  const CalculatePetMoodUseCase();

  // i.e. a focus session of 25 min + short offline activity
  static const int dailyXpGoal = 30;

  PetMood calculate(int xpToday) => xpToday >= dailyXpGoal ? PetMood.happy : PetMood.sad;
}
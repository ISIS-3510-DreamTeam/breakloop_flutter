
class PetStateRequest {
  const PetStateRequest({
    required this.activePetId,
    required this.petMood,
    required this.petUpdatedAt,
  });

  final String activePetId;
  final String petMood;
  final int petUpdatedAt;

  Map<String, dynamic> toJson() => {
    'activePetId': activePetId,
    'petMood': petMood,
    'petUpdatedAt': petUpdatedAt,
  };
}
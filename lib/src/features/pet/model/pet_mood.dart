
enum PetMood {
  happy,
  sad;

  /// Name used by the backend and files in disc ("HAPPY" / "SAD").
  String get apiName => name.toUpperCase();

  static PetMood fromApiName(String? value) =>
      PetMood.values.firstWhere((m) => m.apiName == value, orElse: () => PetMood.sad);
}
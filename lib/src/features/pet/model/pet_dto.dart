
class PetDto {
  const PetDto({required this.id, required this.name, required this.images});

  final String id;
  final String name;
  final Map<String, String> images; // "HAPPY" -> "pets/sprout_happy.png"

  factory PetDto.fromJson(Map<String, dynamic> json) => PetDto(
    id: json['id'] as String,
    name: json['name'] as String,
    images: Map<String, String>.from(json['images'] as Map),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'images': images};
}
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/pet_api.dart';
import '../data/pet_repository.dart';
import '../model/pet_dto.dart';

// Text like "Sprout · Happy" for a pet and its mood
String petLabel(String? petId, String? petMood) {
  if (petId == null) return 'No pet yet';
  final name = _capitalize(petId);
  return petMood == null ? name : '$name · ${_capitalize(petMood)}';
}

String _capitalize(String value) => value.isEmpty
    ? value
    : value[0].toUpperCase() + value.substring(1).toLowerCase();

/// Image of another user's pet in its current mood.
/// It is downloaded from the backend and kept in the disk cache,
/// so it is still shown without connection after the first time
class PetThumbnail extends StatelessWidget {
  final String? petId;
  final String? petMood;
  final double size;

  const PetThumbnail({super.key, this.petId, this.petMood, this.size = 44});

  // The catalog has the image path of each mood. It is read once and shared by all thumbnails
  static Future<List<PetDto>>? _catalog;

  static Future<String?> _imageUrl(String? petId, String? petMood) async {
    if (petId == null) return null;
    final catalog = await (_catalog ??= PetRepository().getCatalog());
    // Without connection and nothing saved, try again next time
    if (catalog.isEmpty) _catalog = null;

    for (final pet in catalog) {
      if (pet.id != petId) continue;
      final path = pet.images[petMood] ?? pet.images.values.firstOrNull;
      return path == null ? null : '$backUrl$path';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Decode the image at the size it is shown, not at its full resolution
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(size * 0.23),
        border: Border.all(color: AppColors.darkCoffee, width: 2),
      ),
      child: FutureBuilder<String?>(
        future: _imageUrl(petId, petMood),
        builder: (context, snapshot) {
          final url = snapshot.data;
          if (url == null) return _buildPaw();
          return CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            memCacheWidth: cacheSize,
            // Pixel art, so it is scaled without blur
            filterQuality: FilterQuality.none,
            placeholder: (_, _) => _buildPaw(),
            errorWidget: (_, _, _) => _buildPaw(),
          );
        },
      ),
    );
  }

  // Shown while loading or when the user has no pet yet
  Widget _buildPaw() =>
      Icon(Icons.pets, size: size * 0.5, color: AppColors.spicyPaprika);
}

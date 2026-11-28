import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../model/achievement_progress.dart';

// Medal image from the backend, cached on disk by cached_network_image.
// Locked medals are shown in grayscale and dimmed.
class AchievementMedal extends StatelessWidget {
  const AchievementMedal({
    super.key,
    required this.progress,
    required this.baseUrl,
  });

  final AchievementProgress progress;
  final Uri baseUrl;

  static const _grayscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: progress.achievement.imageUri(baseUrl).toString(),
      fit: BoxFit.contain,
      placeholder: (_, _) =>
      const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      errorWidget: (_, _, _) =>
      const Icon(Icons.image_not_supported_outlined),
    );

    if (progress.unlocked) return image;

    return Opacity(
      opacity: 0.45,
      child: ColorFiltered(colorFilter: _grayscale, child: image),
    );
  }
}
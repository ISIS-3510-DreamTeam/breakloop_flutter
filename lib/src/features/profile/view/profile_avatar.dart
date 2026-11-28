import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Round profile photo. Uses the photo on the device if there is one,
/// then the cached photo from the URL, and the initials as a fallback.
class ProfileAvatar extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final Uint8List? localPhoto;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.localPhoto,
    this.size = 96,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;

    // Decode the image at the size it is shown, not at its full resolution
    final cacheSize = (size * MediaQuery.devicePixelRatioOf(context)).round();

    final Widget content;
    if (localPhoto != null) {
      content = Image.memory(localPhoto!, fit: BoxFit.cover, cacheWidth: cacheSize);
    } else if (url != null) {
      // Downloaded once and then read from the disk cache, also without connection
      content = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        placeholder: (_, _) => _initials(),
        errorWidget: (_, _, _) => _initials(),
      );
    } else {
      content = _initials();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.inputFill,
        border: Border.all(color: AppColors.darkCoffee, width: 2),
      ),
      child: ClipOval(child: content),
    );
  }

  Widget _initials() {
    final words = displayName.trim().split(RegExp(r'\s+'));
    final initials = words.where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join();

    return Center(
      child: Text(
        initials.toUpperCase(),
        style: AppTextStyles.monoTitle.copyWith(
          fontSize: size * 0.3,
          color: AppColors.paprika700,
        ),
      ),
    );
  }
}

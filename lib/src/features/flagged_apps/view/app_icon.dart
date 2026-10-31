import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../viewmodel/flagged_apps_viewmodel.dart';

//Icon of an installed app. While it loads, or if it fails, shows the first letter of the name
class AppIcon extends StatefulWidget {
  final String packageName;
  final String label;
  final double size;

  const AppIcon({super.key, required this.packageName, required this.label, required this.size});

  @override
  State<AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<AppIcon> {
  late Future<Uint8List?> _icon;

  @override
  void initState() {
    super.initState();
    //Loaded once per widget, in pixels of the screen so it is not blurry
    final sizePx = (widget.size * WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio).round();
    _icon = context.read<FlaggedAppsViewModel>().loadIcon(widget.packageName, sizePx);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.size * 0.25);

    return FutureBuilder<Uint8List?>(
      future: _icon,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return ClipRRect(
            borderRadius: radius,
            child: Image.memory(bytes, width: widget.size, height: widget.size),
          );
        }
        return Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.golden100, borderRadius: radius),
          child: Text(
            widget.label.isEmpty ? '?' : widget.label[0].toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: widget.size * 0.4,
              color: AppColors.paprika700,
            ),
          ),
        );
      },
    );
  }
}

//Daily limit as text
String formatDailyLimit(int? minutes) {
  if (minutes == null || minutes <= 0) return 'No limit';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return '$mins min';
  if (mins == 0) return '$hours h';
  return '$hours h $mins min';
}

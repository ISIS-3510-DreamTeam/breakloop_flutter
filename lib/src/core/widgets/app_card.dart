import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Offset shadowOffset;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.snow,
    this.shadowOffset = const Offset(3, 3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCoffee, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCoffee,
            offset: shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
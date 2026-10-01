import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkCoffee, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.darkCoffee,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
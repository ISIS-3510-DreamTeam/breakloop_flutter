import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

//Small round bordered label, used for status chips and compact buttons
class AppPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const AppPill({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.snow,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.darkCoffee, width: 2),
      ),
      child: Text(label, style: AppTextStyles.monoLabel),
    );

    if (onTap == null) {
      return pill;
    }
    return GestureDetector(onTap: onTap, child: pill);
  }
}

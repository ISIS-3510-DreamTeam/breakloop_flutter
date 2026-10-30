import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

//Small round bordered chip. Filled with paprika when selected
class BreakLoopChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const BreakLoopChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.spicyPaprika : AppColors.snow,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.darkCoffee, width: 2),
        ),
        child: Text(
          label,
          style: AppTextStyles.monoLabel.copyWith(
            color: selected ? AppColors.snow : AppColors.darkCoffee,
          ),
        ),
      ),
    );
  }
}

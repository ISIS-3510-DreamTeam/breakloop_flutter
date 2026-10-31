import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

//Small round bordered chip. Filled with paprika when selected
class BreakLoopChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  //Less padding and smaller text, for rows of chips that must fit in one line
  final bool small;

  const BreakLoopChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = AppColors.spicyPaprika,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.snow,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: AppColors.darkCoffee, width: 2),
        ),
        child: Text(
          label,
          style: AppTextStyles.monoLabel.copyWith(
            fontSize: small ? 11 : null,
            letterSpacing: small ? 0.5 : null,
            color: selected ? AppColors.snow : AppColors.darkCoffee,
          ),
        ),
      ),
    );
  }
}

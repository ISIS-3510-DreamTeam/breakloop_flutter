import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

//Small bordered chip with a hard shadow. Filled with paprika when selected
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.spicyPaprika : AppColors.snow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.darkCoffee, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.darkCoffee, offset: Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 12,
            letterSpacing: 0,
            color: selected ? AppColors.snow : AppColors.darkCoffee,
          ),
        ),
      ),
    );
  }
}

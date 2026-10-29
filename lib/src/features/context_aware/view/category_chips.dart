import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../model/activity_category.dart';
import 'category_style.dart';

//Filter of the activity list. A null category means "All"
class CategoryChips extends StatelessWidget {
  final ActivityCategory? selectedCategory;
  final ValueChanged<ActivityCategory?> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      //Room for the chip shadow
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          _CategoryChip(
            label: 'All',
            selected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          for (final category in ActivityCategory.values) ...[
            const SizedBox(width: 10),
            _CategoryChip(
              emoji: categoryEmoji(category),
              label: categoryLabel(category),
              selected: selectedCategory == category,
              onTap: () => onCategorySelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String? emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.spicyPaprika : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkCoffee, width: 2),
          boxShadow: const [
            BoxShadow(color: AppColors.darkCoffee, offset: Offset(0, 3), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 16)),
            Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                fontSize: 13,
                letterSpacing: 0,
                color: selected ? AppColors.snow : AppColors.darkCoffee,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

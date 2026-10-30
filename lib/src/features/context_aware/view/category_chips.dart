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
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          for (final category in ActivityCategory.values) ...[
            const SizedBox(width: 8),
            _FilterChip(
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

//Light outlined chip, filled with a soft neutral when selected
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.neutral100 : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? AppColors.darkCoffee : AppColors.neutral200, width: 1.5),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.darkCoffee : AppColors.neutral700,
          ),
        ),
      ),
    );
  }
}

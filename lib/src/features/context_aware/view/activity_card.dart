import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../model/offline_activity.dart';
import 'category_style.dart';

//Row of the activity list: category icon, title, duration, XP and category
class ActivityCard extends StatelessWidget {
  final OfflineActivity activity;
  final VoidCallback onTap;

  const ActivityCard({super.key, required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        shadowOffset: const Offset(2, 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor(activity.category),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkCoffee, width: 1.5),
              ),
              child: Icon(categoryIcon(activity.category), size: 22, color: AppColors.darkCoffee),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title, style: textTheme.titleMedium),
                  Text(
                    '${activity.durationMin} MIN · +${activity.xp} XP · ${categoryLabel(activity.category).toUpperCase()}',
                    style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: AppColors.neutral700),
          ],
        ),
      ),
    );
  }
}

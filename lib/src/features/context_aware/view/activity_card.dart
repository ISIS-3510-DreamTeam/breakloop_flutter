import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../model/offline_activity.dart';
import 'category_style.dart';

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
        color: Colors.white,
        shadowOffset: const Offset(0, 4),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.headerBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkCoffee, width: 2),
                boxShadow: const [
                  BoxShadow(color: AppColors.darkCoffee, offset: Offset(0, 3), blurRadius: 0),
                ],
              ),
              child: Text(categoryEmoji(activity.category), style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: textTheme.labelLarge?.copyWith(fontSize: 14, letterSpacing: 0),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${categoryLabel(activity.category)} · ${activity.prompt}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      color: AppColors.darkCoffee.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${activity.durationMin} min',
                  style: textTheme.labelLarge?.copyWith(fontSize: 15, letterSpacing: 0, color: AppColors.spicyPaprika),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${activity.xp} XP',
                  style: textTheme.labelLarge?.copyWith(fontSize: 11, letterSpacing: 0, color: AppColors.fern),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

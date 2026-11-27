import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';

/// Home card that opens the achievements page.
class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/home/achievements'),
      child: AppCard(
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_outlined,
              size: 40,
              color: AppColors.darkCoffee,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ACHIEVEMENTS', style: textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(
                    'See your medals and how close you are to the next one.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkCoffee,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.darkCoffee),
          ],
        ),
      ),
    );
  }
}
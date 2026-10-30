import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../viewmodel/avoided_screen_time_viewmodel.dart';

//"Screen time avoided" card of the Stats view (BQ6), with the same style as "Reduction vs. baseline"
class AvoidedScreenTimeCard extends StatelessWidget {
  const AvoidedScreenTimeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<AvoidedScreenTimeViewModel>().result;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      shadowOffset: const Offset(2, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 16, color: AppColors.neutral700),
              const SizedBox(width: 6),
              Text('SCREEN TIME AVOIDED', style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700)),
            ],
          ),
          const SizedBox(height: 12),
          if (result == null)
            const SizedBox(height: 20)
          else if (result.activitiesThisWeek == 0)
            Text(
              'Complete a suggested offline activity to see how much screen time you avoid.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
            )
          else ...[
            Text('${_formatMs(result.thisWeekMs)} this week', style: textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'From ${result.activitiesThisWeek} suggested ${result.activitiesThisWeek == 1 ? 'activity' : 'activities'} you completed',
              style: textTheme.bodySmall?.copyWith(color: AppColors.neutral700),
            ),
            const SizedBox(height: 12),
            _buildComparison(context, result.thisWeekMs, result.lastWeekMs),
          ],
        ],
      ),
    );
  }

  //Difference with last week, green when the user avoided more
  Widget _buildComparison(BuildContext context, int thisWeekMs, int lastWeekMs) {
    final textTheme = Theme.of(context).textTheme;
    if (lastWeekMs == 0) {
      return Text('Nothing to compare with last week yet', style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700));
    }
    final difference = thisWeekMs - lastWeekMs;
    final more = difference >= 0;
    return Text(
      '${more ? '+' : '−'}${_formatMs(difference.abs())} vs last week',
      style: textTheme.labelSmall?.copyWith(color: more ? AppColors.fern : AppColors.paprika700),
    );
  }

  //Format as "X h Y min", like the other Stats cards
  String _formatMs(int ms) {
    final minutes = ms ~/ 60000;
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60} h ${minutes % 60} min';
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../model/reason_tag.dart';
import '../model/recommendation.dart';
import 'category_style.dart';

//Options of available time: minutes, label and caption
const _timeOptions = [
  (5, '5m', 'Quick'),
  (15, '15m', 'Refresh'),
  (30, '30m', 'Deep'),
];

//Selector of how much time the user has right now
class TimeSelector extends StatelessWidget {
  final int availableMin;
  final ValueChanged<int> onTimeSelected;

  const TimeSelector({super.key, required this.availableMin, required this.onTimeSelected});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        for (final (minutes, label, caption) in _timeOptions) ...[
          if (minutes != _timeOptions.first.$1) const SizedBox(width: 10),
          Expanded(
            child: Builder(
              builder: (context) {
                final selected = availableMin == minutes;
                final textColor = selected ? AppColors.snow : AppColors.darkCoffee;
                return GestureDetector(
                  onTap: () => onTimeSelected(minutes),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.spicyPaprika : AppColors.snow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.darkCoffee, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(label, style: AppTextStyles.monoLabel.copyWith(color: textColor)),
                        Text(
                          caption.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: textColor.withValues(alpha: selected ? 0.9 : 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

//"Suggested for you" card: best activity for the current context and the available time
class SuggestedCard extends StatelessWidget {
  final Recommendation? suggestion;
  final int availableMin;
  final bool isWeatherAvailable;
  final ValueChanged<String> onActivityTap;

  const SuggestedCard({
    super.key,
    required this.suggestion,
    required this.availableMin,
    required this.isWeatherAvailable,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suggestion = this.suggestion;

    return AppCard(
      color: AppColors.golden100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, size: 14, color: AppColors.paprika700),
              const SizedBox(width: 4),
              Expanded(
                child: Text('SUGGESTED FOR YOU', style: textTheme.labelSmall?.copyWith(color: AppColors.paprika700)),
              ),
              //The suggestion does not use the weather when it is not available
              if (!isWeatherAvailable)
                Text('OFFLINE-BASED', style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700)),
            ],
          ),
          if (suggestion == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  'Nothing fits in $availableMin min. Try more time.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: categoryColor(suggestion.activity.category),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkCoffee, width: 2),
                  ),
                  child: Icon(categoryIcon(suggestion.activity.category), size: 28, color: AppColors.darkCoffee),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(suggestion.activity.title, style: textTheme.titleLarge),
                      Text(
                        reasonText(suggestion.reasons, availableMin),
                        style: textTheme.bodySmall?.copyWith(color: AppColors.fern),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 14),
              child: Row(
                children: [
                  _MetaItem(icon: Icons.timer_outlined, text: '${suggestion.activity.durationMin} MIN', color: AppColors.darkCoffee),
                  const SizedBox(width: 14),
                  _MetaItem(icon: Icons.bolt_outlined, text: '+${suggestion.activity.xp} XP', color: AppColors.fern),
                  const SizedBox(width: 14),
                  Text(
                    categoryLabel(suggestion.activity.category).toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700),
                  ),
                ],
              ),
            ),
            AppButton(
              label: 'Do this now',
              onPressed: () => onActivityTap(suggestion.activity.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _MetaItem({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}

//Shows at most two reasons of the suggestion
String reasonText(List<ReasonTag> reasons, int availableMin) {
  if (reasons.isEmpty) {
    return 'A good break for right now';
  }
  return reasons.take(2).map((tag) {
    switch (tag) {
      case ReasonTag.goodWeather:
        return 'Good weather for it';
      case ReasonTag.fitsAvailableTime:
        return 'Fits your $availableMin min';
      case ReasonTag.rightTimeOfDay:
        return 'Great for this time of day';
      case ReasonTag.matchesInterest:
        return 'Matches your interests';
    }
  }).join(' · ');
}

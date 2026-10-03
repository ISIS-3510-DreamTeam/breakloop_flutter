import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../model/reason_tag.dart';
import '../model/recommendation.dart';

//"Suggested for right now" card: best activity for the current context and the available time
class SuggestedCard extends StatelessWidget {
  final Recommendation? suggestion;
  final int availableMin;
  final bool isWeatherAvailable;
  final ValueChanged<int> onTimeSelected;
  final ValueChanged<String> onActivityTap;

  const SuggestedCard({
    super.key,
    required this.suggestion,
    required this.availableMin,
    required this.isWeatherAvailable,
    required this.onTimeSelected,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suggestion = this.suggestion;

    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '✨ SUGGESTED FOR RIGHT NOW',
                  style: textTheme.labelLarge?.copyWith(fontSize: 12, letterSpacing: 0.5, color: AppColors.spicyPaprika),
                ),
              ),
              //The suggestion does not use the weather when it is not available
              if (!isWeatherAvailable)
                Text(
                  'OFFLINE-BASED',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                    color: AppColors.darkCoffee.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                _TimeChip(label: '5m quick', selected: availableMin == 5, onTap: () => onTimeSelected(5)),
                const SizedBox(width: 8),
                _TimeChip(label: '15m refresh', selected: availableMin == 15, onTap: () => onTimeSelected(15)),
                const SizedBox(width: 8),
                _TimeChip(label: '30m deep', selected: availableMin == 30, onTap: () => onTimeSelected(30)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (suggestion == null)
            Text(
              'Nothing fits in $availableMin min. Try more time.',
              style: textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.darkCoffee.withValues(alpha: 0.75)),
            )
          else ...[
            Text(
              suggestion.activity.title,
              style: textTheme.labelLarge?.copyWith(fontSize: 17, letterSpacing: 0),
            ),
            const SizedBox(height: 4),
            Text(
              reasonText(suggestion.reasons, availableMin),
              style: textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.fern),
            ),
            const SizedBox(height: 6),
            Text(
              '⏱ ${suggestion.activity.durationMin} MIN · ⚡ +${suggestion.activity.xp} XP',
              style: textTheme.labelLarge?.copyWith(fontSize: 11, letterSpacing: 0, color: AppColors.darkCoffee.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 14),
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

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeChip({required this.label, required this.selected, required this.onTap});

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

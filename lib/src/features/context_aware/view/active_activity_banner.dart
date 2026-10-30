import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../viewmodel/active_activity_viewmodel.dart';

//Strip under the header that shows the activity in progress or finished. Same as ActiveActivityBanner in the Kotlin app
class ActiveActivityBanner extends StatelessWidget {
  const ActiveActivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ActiveActivityViewModel>().uiState;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: switch (state) {
        ActiveActivityHidden() => const SizedBox(width: double.infinity),
        ActiveActivityRunning running => _BannerStrip(
            text: '${running.title} · ${_formatRemaining(running.remainingSeconds)} left',
            background: AppColors.golden100,
            accent: AppColors.paprika700,
            icon: Icons.timer_outlined,
            activityId: running.activityId,
          ),
        ActiveActivityFinished finished => _BannerStrip(
            text: '${finished.title} done! Tap to log it',
            background: AppColors.fern100,
            accent: AppColors.fern,
            icon: Icons.check_circle_outline,
            activityId: finished.activityId,
          ),
      },
    );
  }

  String _formatRemaining(int seconds) {
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}

class _BannerStrip extends StatelessWidget {
  final String text;
  final Color background;
  final Color accent;
  final IconData icon;
  final String activityId;

  const _BannerStrip({
    required this.text,
    required this.background,
    required this.accent,
    required this.icon,
    required this.activityId,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      child: InkWell(
        //Opens the activity in the Offline tab, from any tab
        onTap: () => context.go('/offline/activity/$activityId?fromSuggestion=false'),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.darkCoffee, width: 1.5)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              const Icon(Icons.keyboard_arrow_right, size: 20, color: AppColors.neutral700),
            ],
          ),
        ),
      ),
    );
  }
}

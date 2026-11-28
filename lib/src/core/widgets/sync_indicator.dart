import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/achievements/viewmodel/achievements_viewmodel.dart';
import '../../features/goals/viewmodel/goals_viewmodel.dart';
import '../theme/app_colors.dart';

/// Header icon shown while the streak or an unlock is waiting to reach the cloud.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final streakPending = context.select<GoalsViewModel, bool>((vm) => vm.streakPendingSync);
    final pendingUnlocks = context.select<AchievementsViewModel, int>((vm) => vm.pendingUnlocks);

    if (!streakPending && pendingUnlocks == 0) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: 'Waiting to sync',
      icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.darkCoffee),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(streakPending, pendingUnlocks))),
        );
      },
    );
  }

  String _message(bool streakPending, int pendingUnlocks) {
    final parts = [
      if (streakPending) 'streak',
      if (pendingUnlocks > 0) '$pendingUnlocks achievement(s)',
    ];
    return 'Waiting to sync: ${parts.join(' and ')}. '
        'It will upload when you are back online.';
  }
}
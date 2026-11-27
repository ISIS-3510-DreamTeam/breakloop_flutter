import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../data/achievements_catalog_api.dart';
import '../model/achievement_progress.dart';
import '../viewmodel/achievements_viewmodel.dart';
import 'achievement_medal.dart';

// For testing
import 'dev_tools.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AchievementsViewModel>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AchievementsViewModel>();
    final baseUrl = context.read<AchievementsCatalogApi>().baseUrl;

    return Scaffold(
      backgroundColor: AppColors.snow,
      appBar: AppBar(
        title: DevTapTarget(
          onUnlock: () => showStreakDebugSheet(context),
          child: const Text('Achievements'),
        ),
        backgroundColor: AppColors.snow,
        foregroundColor: AppColors.darkCoffee,
      ),
      body: SafeArea(child: _body(vm, baseUrl)),
    );
  }

  Widget _body(AchievementsViewModel vm, Uri baseUrl) {
    switch (vm.status) {
      case AchievementsStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case AchievementsStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Couldn't load achievements"),
              TextButton(
                onPressed: () => vm.load(),
                child: const Text('Try again'),
              ),
            ],
          ),
        );

      case AchievementsStatus.empty:
        return const Center(child: Text('No available achievements yet'));

      case AchievementsStatus.content:
        return Column(
          children: [
            if (vm.fromCache)
              Container(
                width: double.infinity,
                color: AppColors.golden100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text(
                  'Offline: showing last saved data',
                  style: TextStyle(color: AppColors.darkCoffee),
                ),
              ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.78,
                ),
                itemCount: vm.items.length,
                itemBuilder: (_, i) => _AchievementTile(
                  progress: vm.items[i],
                  baseUrl: baseUrl,
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.progress, required this.baseUrl});

  final AchievementProgress progress;
  final Uri baseUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        border: Border.all(color: AppColors.darkCoffee, width: 2),
      ),
      child: Column(
        children: [
          Expanded(child: AchievementMedal(progress: progress, baseUrl: baseUrl)),
          const SizedBox(height: 8),
          Text(
            progress.achievement.name,
            textAlign: TextAlign.center,
            style: theme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.darkCoffee,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle(),
            textAlign: TextAlign.center,
            style: theme.bodySmall?.copyWith(color: AppColors.neutral700),
          ),
        ],
      ),
    );
  }

  String _subtitle() {
    final date = progress.unlockedAt;
    if (date != null) {
      final d = date.toLocal();
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      return 'Unlocked $day/$month/${d.year}';
    }
    final target = progress.achievement.target;
    final current = progress.current.clamp(0, target);
    return '$current/$target';
  }
}
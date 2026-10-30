import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/screen_time_progress_viewmodel.dart';
import '../../goals/viewmodel/goals_viewmodel.dart';
import '../../flagged_apps/view/flagged_apps_card.dart';
import '../../context_aware/view/avoided_screen_time_card.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class ScreenTimeProgressPage extends StatefulWidget {
  const ScreenTimeProgressPage({super.key});

  @override
  State<ScreenTimeProgressPage> createState() => _ScreenTimeProgressPageState();
}

class _ScreenTimeProgressPageState extends State<ScreenTimeProgressPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //The user leaves the app to enable the usage access in the Android settings, so we check again when they come back
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final vm = context.read<ScreenTimeProgressViewModel>();
    if (state == AppLifecycleState.resumed && vm.status == ScreenTimeProgressStatus.permissionRequired) {
      vm.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScreenTimeProgressViewModel>();

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: _buildBody(vm),
    );
  }

  Widget _buildBody(ScreenTimeProgressViewModel vm) {
    final textTheme = Theme.of(context).textTheme;

    switch (vm.status) {
      case ScreenTimeProgressStatus.idle:
      case ScreenTimeProgressStatus.loading:
        return const Center(child: CircularProgressIndicator(color: AppColors.spicyPaprika));
      case ScreenTimeProgressStatus.permissionRequired:
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'BreakLoop needs access to your app usage to measure your screen time. Please enable it in the settings and come back.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Grant access', onPressed: vm.requestPermission),
              ],
            ),
          ),
        );
      case ScreenTimeProgressStatus.error:
        return _buildMessage('Oops, we could not load your screen time. Try again later.');
      case ScreenTimeProgressStatus.loaded:
        break;
    }

    final currentWeek = vm.currentWeek;
    if (currentWeek == null) {
      return _buildMessage('No screen-time data yet.');
    }

    final streak = context.watch<GoalsViewModel>().goal.currentStreak;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTitle(),
        const SizedBox(height: 24),
        _buildTodayCard(vm),
        const SizedBox(height: 24),
        Row(
          children: [
            //No focus minutes nor best streak yet
            Expanded(
              child: _buildMiniMetric(
                icon: Icons.timer_outlined,
                label: 'Focus minutes',
                value: '—',
                iconBackground: AppColors.fern100,
                iconColor: AppColors.fern,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniMetric(
                icon: Icons.local_fire_department_outlined,
                label: 'Current streak',
                value: '${streak}d',
                iconBackground: AppColors.paprika100,
                iconColor: AppColors.spicyPaprika,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniMetric(
                icon: Icons.emoji_events_outlined,
                label: 'Best streak',
                value: '—',
                iconBackground: AppColors.golden100,
                iconColor: AppColors.goldenOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(Icons.calendar_today_outlined, 'WEEKLY SCREEN RHYTHM'),
              const SizedBox(height: 12),
              _buildWeeklyBars(currentWeek.dailyMinutes, vm.todayMinutes != null),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.bar_chart, size: 14, color: AppColors.neutral700),
                  const SizedBox(width: 6),
                  Text(
                    'Average: ${_formatMinutes(currentWeek.averageDailyMinutes.round())}',
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const FlaggedAppsCard(),
        const SizedBox(height: 24),
        _buildReductionCard(vm),
        const SizedBox(height: 24),
        const AvoidedScreenTimeCard(),
      ],
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  Widget _buildTitle() {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('YOUR PROGRESS', style: textTheme.labelSmall?.copyWith(color: AppColors.paprika700)),
        const SizedBox(height: 2),
        Text('Mindful reduction metrics', style: textTheme.titleLarge),
        Row(
          children: [
            Expanded(
              child: Text(
                'vs baseline, this week',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/stats/deep-stats'),
              child: Text(
                'Deep Stats →',
                style: textTheme.labelLarge?.copyWith(color: AppColors.paprika700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  //Highlighted card with the screen time of today
  Widget _buildTodayCard(ScreenTimeProgressViewModel vm) {
    final textTheme = Theme.of(context).textTheme;
    final change = vm.changeVsLastWeekPercent;
    final lower = change != null && change <= 0;

    final Color chipBackground;
    final Color chipColor;
    if (change == null) {
      chipBackground = AppColors.snow;
      chipColor = AppColors.neutral700;
    } else if (lower) {
      chipBackground = AppColors.fern100;
      chipColor = AppColors.fern;
    } else {
      chipBackground = AppColors.paprika100;
      chipColor = AppColors.paprika700;
    }

    return AppCard(
      color: AppColors.golden100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone_android_outlined, size: 14, color: AppColors.paprika700),
              const SizedBox(width: 6),
              Text("TODAY'S SCREEN TIME", style: textTheme.labelSmall?.copyWith(color: AppColors.paprika700)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 12),
            child: Text(_formatMinutes(vm.todayMinutes ?? 0), style: textTheme.headlineLarge),
          ),
          //Change against last week, or a neutral message when there is nothing to compare
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: chipBackground,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: AppColors.darkCoffee, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (change != null) ...[
                  Icon(lower ? Icons.trending_down : Icons.trending_up, size: 14, color: chipColor),
                  const SizedBox(width: 4),
                ],
                Text(
                  change == null ? 'A fresh start!' : '${change.abs()}% vs last week',
                  style: textTheme.labelSmall?.copyWith(color: chipColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Small metric card with a colored icon, three in a row
  Widget _buildMiniMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color iconBackground,
    required Color iconColor,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(12),
      shadowOffset: const Offset(2, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.darkCoffee, width: 1.5),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                color: value == '—' ? AppColors.neutral500 : AppColors.darkCoffee,
              ),
            ),
          ),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.neutral700),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.neutral700)),
      ],
    );
  }

  //Bars of the current week from Sunday to Saturday, made of stacked blocks in pixel-art style
  Widget _buildWeeklyBars(List<int?> dailyMinutes, bool hasToday) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    const blockHeight = 10.0;
    const blockGap = 2.0;
    final textTheme = Theme.of(context).textTheme;
    final todayIndex = hasToday ? DateTime.now().weekday % 7 : -1;
    final maxMinutes = dailyMinutes.whereType<int>().fold<int>(1, (max, minutes) => minutes > max ? minutes : max);

    return SizedBox(
      height: 144,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < 7; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final minutes = dailyMinutes[i];
                        //Day without data: a thin empty bar
                        if (minutes == null) {
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.neutral100,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                          );
                        }
                        final maxBlocks = (constraints.maxHeight / (blockHeight + blockGap)).floor();
                        var blocks = (minutes / maxMinutes * 0.85 * maxBlocks).round();
                        if (blocks == 0 && minutes > 0) {
                          blocks = 1;
                        }
                        final color = i == todayIndex ? AppColors.spicyPaprika : AppColors.goldenOrange;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            for (var b = 0; b < blocks; b++)
                              Container(
                                height: blockHeight,
                                margin: const EdgeInsets.only(top: blockGap),
                                decoration: BoxDecoration(
                                  color: color,
                                  border: Border.all(color: AppColors.darkCoffee, width: 1),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayLabels[i],
                    style: textTheme.labelSmall?.copyWith(
                      color: i == todayIndex ? AppColors.spicyPaprika : AppColors.neutral700,
                      fontWeight: i == todayIndex ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  //Reduction of the current week against the baseline week, with the progress toward the -20% goal
  Widget _buildReductionCard(ScreenTimeProgressViewModel vm) {
    final textTheme = Theme.of(context).textTheme;
    final reduction = vm.reductionPercent;
    final baseline = vm.baselineWeek;
    //The first week is the baseline itself, so there is nothing to compare yet
    final hasComparison = reduction != null && baseline != null && vm.weeks.length > 1;

    return AppCard(
      shadowOffset: const Offset(2, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            hasComparison && reduction > 0 ? Icons.trending_down : Icons.trending_up,
            'REDUCTION VS. BASELINE',
          ),
          const SizedBox(height: 12),
          if (!hasComparison)
            Text('Calculating your baseline...', style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700))
          else ...[
            Text(
              'Your weekly average is ${reduction.abs().round()}% ${reduction > 0 ? 'lower' : 'higher'} than your baseline',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Baseline: ${_formatMinutes(baseline.averageDailyMinutes.round())} / day',
              style: textTheme.bodySmall?.copyWith(color: AppColors.neutral700),
            ),
            const SizedBox(height: 12),
            _buildPixelProgressBar(reduction / 20),
            const SizedBox(height: 12),
            Text('Progress toward the -20% goal', style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700)),
          ],
        ],
      ),
    );
  }

  //Progress bar made of square segments, like a health bar
  Widget _buildPixelProgressBar(double progress) {
    const segments = 20;
    final filled = (progress.clamp(0, 1) * segments).round();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.darkCoffee, width: 2),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: Container(height: 12, color: i < filled ? AppColors.fern : AppColors.neutral100),
            ),
          ],
        ],
      ),
    );
  }

  //Format minutes as "X h Y min"
  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      return '${minutes ~/ 60} h ${minutes % 60} min';
    }
  }
}

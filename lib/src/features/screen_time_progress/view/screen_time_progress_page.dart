import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/screen_time_progress_viewmodel.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';

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

  //MOCK DATA: Focus and streak values. TODO: replace when Focus and streaks are implemented
  static const _mockFocusMinutes = '75 min';
  static const _mockFocusSprints = '3 completed sprints';
  static const _mockCurrentStreak = '12 Days';
  static const _mockCurrentStreakTarget = 'Under 4h target daily';
  static const _mockBestStreak = '18 Days';
  static const _mockBestStreakToBeat = '6 days to beat!';

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScreenTimeProgressViewModel>();

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: Column(
        children: [
          Expanded(child: _buildBody(vm)),
        ],
      ),
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
                AppButton(label: 'GRANT ACCESS', onPressed: vm.requestPermission),
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        _buildTitle(),
        const SizedBox(height: 20),
        _buildCardRow(
          _buildStatCard(
            label: 'Weekly screen time',
            value: _formatMinutes(currentWeek.averageDailyMinutes),
            footer: _buildReduction(vm),
          ),
          _buildStatCard(
            label: 'Focus Minutes',
            value: _mockFocusMinutes,
            valueColor: AppColors.spicyPaprika,
            footer: Text(_mockFocusSprints, style: _footerStyle()),
          ),
        ),
        const SizedBox(height: 12),
        _buildCardRow(
          _buildStatCard(
            label: 'Current Streak',
            value: _mockCurrentStreak,
            footer: Text(_mockCurrentStreakTarget, style: _footerStyle()),
          ),
          _buildStatCard(
            label: 'Best Streak Record',
            value: _mockBestStreak,
            valueColor: AppColors.spicyPaprika,
            footer: Text(_mockBestStreakToBeat, style: _footerStyle().copyWith(color: AppColors.fern, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          color: Colors.white,
          shadowOffset: const Offset(0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily screen time this week', style: _labelStyle()),
              const SizedBox(height: 16),
              _buildDailyBarChart(context, currentWeek.dailyMinutes),
            ],
          ),
        ),
        //TODO: Tamed distraction loops card
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR PROGRESS', style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Mindful reduction metrics vs baseline',
                style: textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.spicyPaprika),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppPill(label: 'Deep Stats →', onTap: () => context.push('/stats/deep-stats')),
      ],
    );
  }

  //Two cards side by side with the same height
  Widget _buildCardRow(Widget left, Widget right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Widget footer,
    Color valueColor = AppColors.darkCoffee,
  }) {
    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Label and number stay in one line and scale down on narrow screens instead of wrapping.
          //softWrap false keeps IntrinsicHeight from measuring them as if they wrapped
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label, softWrap: false, style: _labelStyle()),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, softWrap: false, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 26, color: valueColor)),
          ),
          const SizedBox(height: 4),
          footer,
        ],
      ),
    );
  }

  TextStyle? _labelStyle() {
    return Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 13, letterSpacing: 0);
  }

  TextStyle _footerStyle() {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12, fontWeight: FontWeight.w600);
  }

  //Vertical bar chart of the current week, one bar per day from Sunday to Saturday
  Widget _buildDailyBarChart(BuildContext context, List<int?> dailyMinutes) {
    const dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const maxBarHeight = 120.0;
    final textTheme = Theme.of(context).textTheme;
    final barColor = Theme.of(context).colorScheme.primary;
    //Longest day is used to scale the bars
    final maxMinutes = dailyMinutes.fold<int>(0, (max, minutes) {
      if (minutes != null && minutes > max) {
        return minutes;
      } else {
        return max;
      }
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              children: [
                //Days without data (e.g. future days) show no value and no bar
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(dailyMinutes[i] == null ? '' : _formatShortMinutes(dailyMinutes[i]!), style: textTheme.labelSmall),
                ),
                const SizedBox(height: 4),
                Container(
                  height: maxMinutes == 0 ? 0 : maxBarHeight * (dailyMinutes[i] ?? 0) / maxMinutes,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(fit: BoxFit.scaleDown, child: Text(dayLabels[i])),
              ],
            ),
          ),
      ],
    );
  }

  //Reduction against the fixed baseline (first week of use)
  Widget _buildReduction(ScreenTimeProgressViewModel vm) {
    final reduction = vm.reductionPercent;
    final style = _footerStyle();
    if (vm.weeks.length == 1) {
      return Text('This is your baseline week', style: style);
    }
    if (reduction == null) {
      return Text('No baseline to compare yet', style: style);
    }
    if (reduction >= 0) {
      return Text(
        '${reduction.toStringAsFixed(1)}% less than your first week',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: style.copyWith(color: AppColors.fern, fontWeight: FontWeight.bold),
      );
    }
    return Text(
      '${(-reduction).toStringAsFixed(1)}% more than your first week',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(color: AppColors.spicyPaprika, fontWeight: FontWeight.bold),
    );
  }

  //Format minutes as "X h Y min"
  String _formatMinutes(double minutes) {
    final total = minutes.round();
    if (total < 60) {
      return '$total min';
    } else {
      return '${total ~/ 60} h ${(total % 60).toString().padLeft(2, '0')} min';
    }
  }

  //Format minutes as "X h Y m" so it fits above a bar.
  String _formatShortMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
    }
  }

}

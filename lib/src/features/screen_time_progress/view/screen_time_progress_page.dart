import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/screen_time_progress_viewmodel.dart';

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

  //Palette colors for positive (reduction) and negative (increase) progress
  static const _fern = Color(0xFF546A42);
  static const _spicyPaprika = Color(0xFFC85A32);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScreenTimeProgressViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: _buildBody(context, vm),
    );
  }

  Widget _buildBody(BuildContext context, ScreenTimeProgressViewModel vm) {
    switch (vm.status) {
      case ScreenTimeProgressStatus.idle:
      case ScreenTimeProgressStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ScreenTimeProgressStatus.permissionRequired:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'BreakLoop needs access to your app usage to measure your screen time. Please enable it in the settings and come back.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: vm.requestPermission,
                  child: const Text('Grant access'),
                ),
              ],
            ),
          ),
        );
      case ScreenTimeProgressStatus.error:
        return const Center(child: Text('Oops, we could not load your screen time. Try again later.'));
      case ScreenTimeProgressStatus.loaded:
        break;
    }

    final currentWeek = vm.currentWeek;
    if (currentWeek == null) {
      return const Center(child: Text('No screen-time data yet.'));
    }

    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Your progress', style: textTheme.titleLarge),
        const Text('Mindful reduction metrics vs baseline'),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly screen time'),
                Text(_formatMinutes(currentWeek.averageDailyMinutes), style: textTheme.headlineMedium),
                _buildReduction(vm),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily screen time this week', style: textTheme.titleMedium),
                const SizedBox(height: 16),
                _buildDailyBarChart(context, currentWeek.dailyMinutes),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //Vertical bar chart of the current week, one bar per day from Sunday to Saturday
  Widget _buildDailyBarChart(BuildContext context, List<int?> dailyMinutes) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
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
                Text(dayLabels[i]),
              ],
            ),
          ),
      ],
    );
  }

  //Reduction against the fixed baseline (first week of use)
  Widget _buildReduction(ScreenTimeProgressViewModel vm) {
    final reduction = vm.reductionPercent;
    if (vm.weeks.length == 1) {
      return const Text('This is your baseline week');
    }
    if (reduction == null) {
      return const Text('No baseline to compare yet');
    }
    if (reduction >= 0) {
      return Text('${reduction.toStringAsFixed(1)}% less than your first week', style: const TextStyle(color: _fern));
    }
    return Text('${(-reduction).toStringAsFixed(1)}% more than your first week', style: const TextStyle(color: _spicyPaprika));
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

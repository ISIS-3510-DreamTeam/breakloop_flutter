import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/data/auth_repository.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/model/goal_model.dart';
import '../data/achievements_repository.dart';
import '../viewmodel/achievements_viewmodel.dart';

/// Developer tools are on in debug builds, or in any build started with
/// --dart-define=DEV_TOOLS=true (useful to test on a phone in profile mode).
const bool kDevToolsEnabled = kDebugMode || bool.fromEnvironment('DEV_TOOLS');

/// Hidden trigger: tapping [child] [taps] times within [window] calls [onUnlock].
/// Does nothing when kDevToolsEnabled is false.
class DevTapTarget extends StatefulWidget {
  const DevTapTarget({
    super.key,
    required this.child,
    required this.onUnlock,
    this.taps = 7,
    this.window = const Duration(seconds: 2),
  });

  final Widget child;
  final VoidCallback onUnlock;
  final int taps;
  final Duration window;

  @override
  State<DevTapTarget> createState() => _DevTapTargetState();
}

class _DevTapTargetState extends State<DevTapTarget> {
  int _count = 0;
  DateTime? _firstTap;

  void _onTap() {
    if (!kDevToolsEnabled) return;

    final now = DateTime.now();
    final first = _firstTap;
    if (first == null || now.difference(first) > widget.window) {
      _firstTap = now;
      _count = 0;
    }
    _count++;

    if (_count >= widget.taps) {
      _firstTap = null;
      _count = 0;
      widget.onUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: widget.child,
    );
  }
}

/// Bottom sheet to change the streak, reset unlocks and re-evaluate achievements.
Future<void> showStreakDebugSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _StreakDebugSheet(),
  );
}

class _StreakDebugSheet extends StatefulWidget {
  const _StreakDebugSheet();

  @override
  State<_StreakDebugSheet> createState() => _StreakDebugSheetState();
}

class _StreakDebugSheetState extends State<_StreakDebugSheet> {
  final _customController = TextEditingController();
  GoalModel? _goal;
  bool _busy = false;
  String _lastAction = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final goal = await context.read<GoalsRepository>().getCurrentGoal();
    if (mounted) setState(() => _goal = goal);
  }

  // Uses GoalsRepository.updateStreak, which also notifies GoalsViewModel.
  // The evaluation date is set to today, so the day rollover does not
  // change the value we just set.
  Future<void> _setStreak(int value) async {
    final newStreak = value < 0 ? 0 : value;
    final goals = context.read<GoalsRepository>();
    final achievements = context.read<AchievementsViewModel>();

    setState(() => _busy = true);

    final now = DateTime.now();
    await goals.updateStreak(
      newStreak: newStreak,
      lastEvaluationDate: DateTime(now.year, now.month, now.day),
      streakBrokenToday: false,
    );
    await achievements.load();
    await _refresh();

    if (!mounted) return;
    setState(() {
      _busy = false;
      _lastAction = 'Streak = $newStreak';
    });
  }

  // Deletes the stored unlocks of the current user, then evaluates again.
  // Medals whose rule is still met will come back right away.
  /// Deletes the unlocks in the cloud and on this device, then evaluates again.
  /// Medals whose rule is still met come back right away.
  Future<void> _resetUnlocks() async {
    final uid = context.read<AuthRepository>().currentUser?.uid;
    if (uid == null) return;

    final repository = context.read<AchievementsRepository>();
    final achievements = context.read<AchievementsViewModel>();

    setState(() => _busy = true);
    try {
      await repository.deleteUnlocks(uid);
      await achievements.load();
      if (mounted) setState(() => _lastAction = 'Achievements reset');
    } catch (e) {
      if (mounted) setState(() => _lastAction = 'Could not reset (check the network)');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final goal = _goal;
    final current = goal?.currentStreak ?? 0;
    final last = goal?.lastEvaluationDate;
    final lastText = last == null
        ? 'never'
        : '${last.year}-${_two(last.month)}-${_two(last.day)}';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dev tools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Current streak: $current'),
            Text('Last evaluation: $lastText'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _busy ? null : () => _setStreak(current + 1),
                  child: const Text('+1'),
                ),
                for (final value in [0, 6, 7, 29, 30])
                  OutlinedButton(
                    onPressed: _busy ? null : () => _setStreak(value),
                    child: Text('= $value'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custom Streak',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () {
                    final value =
                    int.tryParse(_customController.text.trim());
                    if (value != null) _setStreak(value);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => context.read<AchievementsViewModel>().load(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reevaluate achievements'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _resetUnlocks,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset achievements'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Erases all unlocked achievements, here and in the cloud. If the streak '
                  'or current usage still meets a rule, the badge is unlocked again. '
                  'To see them locked, set the streak to 0 first.',
              style: TextStyle(fontSize: 12),
            ),
            if (_lastAction.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_lastAction),
              ),
          ],
        ),
      ),
    );
  }
}
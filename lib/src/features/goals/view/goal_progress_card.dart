import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/goals_viewmodel.dart';



class GoalProgressCard extends StatefulWidget {
  const GoalProgressCard({super.key});

  @override
  State<GoalProgressCard> createState() => _GoalProgressCardState();

}

class _GoalProgressCardState extends State<GoalProgressCard> with WidgetsBindingObserver {

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final vm = context.read<GoalsViewModel>();
    if (state == AppLifecycleState.resumed && vm.goal.isConfigured) {
      vm.reloadUsage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<GoalsViewModel>();
    return switch (vm.status){
      GoalsStatus.loading => const Center(child: CircularProgressIndicator()),
      GoalsStatus.needsSetup => _SetupView(
        onConfirm: (minutes) => context.read<GoalsViewModel>().setDailyLimit(minutes),
      ),
      GoalsStatus.permissionRequired => _PermissionView(
        onRequest: () => context.read<GoalsViewModel>().requestPermission(),
      ),
      GoalsStatus.error => const Text('Error loading screen time data.'),
      GoalsStatus.active => _ActiveView(goal: vm.goal, progress: vm.progress!),

    };
  }
}

class _SetupView extends StatefulWidget {
  final void Function(int minutes) onConfirm;
  const _SetupView({required this.onConfirm});

  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  final _controller = TextEditingController(text: '120');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No goal set yet. Enter daily limit (minutes):'),
        TextField(controller: _controller, keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => widget.onConfirm(int.tryParse(_controller.text) ?? 120),
          child: const Text('Save goal'),
        ),
      ],
    );
  }
}

class _PermissionView extends StatelessWidget {
  final VoidCallback onRequest;
  const _PermissionView({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('BreakLoop needs usage access to track your screen time.'),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRequest, child: const Text('Grant access')),
      ],
    );
  }
}

class _ActiveView extends StatefulWidget {
  final dynamic goal;
  final dynamic progress;
  const _ActiveView({required this.goal, required this.progress});

  @override
  State<_ActiveView> createState() => _ActiveViewState();

}

class _ActiveViewState extends State<_ActiveView> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    if (_isEditing){
      return _EditGoalView(
        currentMinutes: widget.goal.dailyLimitMinutes!,
        onConfirm: (minutes) {
          context.read<GoalsViewModel>().scheduleNewLimit(minutes);
          setState(() => _isEditing = false);
        },
        onCancel: () => setState(() => _isEditing = false),
      );

    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Daily limit: ${widget.goal.dailyLimitMinutes} minutes'),
        Text('Used today: ${widget.progress.usedMinutes} minutes'),
        Text('Remaining: ${widget.progress.remainingMinutes} minutes'),
        Text('Fraction used: ${(widget.progress.fractionUsed * 100).toStringAsFixed(0)}%'),
        Text('Over goal? ${widget.progress.isOverGoal}'),
        Text('Reached 80%? ${widget.progress.hasReachedThreshold80}'),
        Text('Current streak: ${widget.goal.currentStreak} days'),

        if (widget.goal.pendingDailyLimitMinutes != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'New limit of ${widget.goal.pendingDailyLimitMinutes} min takes effect tomorrow'

            )
          ),
        const SizedBox(height: 12,),
        TextButton(
          onPressed: () => setState(() => _isEditing = true),
          child: const Text('Edit Goal'),
        )
      ],
    );
  }
}

class _EditGoalView extends StatefulWidget {
  final int currentMinutes;
  final void Function(int minutes) onConfirm;
  final VoidCallback onCancel;

  const _EditGoalView({
    required this.currentMinutes,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_EditGoalView> createState() => _EditGoalViewState();
}

class _EditGoalViewState extends State<_EditGoalView> {
  late final _controller = TextEditingController(text: widget.currentMinutes.toString());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('New daily limit (minutes):'),
        TextField(controller: _controller, keyboardType: TextInputType.number),
        const Text(
          'This will take effect tomorrow, to keep your streak fair.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                final minutes = int.tryParse(_controller.text);
                if (minutes != null && minutes >= 15 && minutes <= 720) {
                  widget.onConfirm(minutes);
                }
              },
              child: const Text('Confirm'),
            ),
            TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
          ],
        ),
      ],
    );
  }
}
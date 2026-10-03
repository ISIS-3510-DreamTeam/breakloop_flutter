import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/goals_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';



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
    final textTheme = Theme.of(context).textTheme;
    final progress = widget.progress;
    final goal = widget.goal;

    final usedLabel = _formatMinutes(progress.usedMinutes as int);
    final goalLabel = _formatMinutes(goal.dailyLimitMinutes as int);
    final remainingMinutes = progress.remainingMinutes as int;
    final fractionRemainingPercent = ((1 - (progress.fractionUsed as double)) * 100).clamp(0, 100).round();
    final isOverGoal = progress.isOverGoal as bool;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TODAY'S SCREEN TIME", style: textTheme.labelLarge),
                GestureDetector(
                  onTap: () => setState(() => _isEditing = true),
                  child: const Icon(Icons.settings_outlined, size: 18, color: AppColors.darkCoffee),
                )
              ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(usedLabel, style: textTheme.headlineMedium),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isOverGoal ? AppColors.spicyPaprika : AppColors.fern).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOverGoal ? '+$fractionRemainingPercent%' : '-$fractionRemainingPercent%',
                  style: textTheme.bodyMedium?.copyWith(
                    color: isOverGoal ? AppColors.spicyPaprika : AppColors.fern,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 4),

          Text(
            'Goal < $goalLabel · ${_formatMinutes(remainingMinutes)} cushion left',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.darkCoffee),
          ),
          const SizedBox(height: 16,),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (progress.fractionUsed as double).clamp(0, 1),
              minHeight: 8,
              backgroundColor: AppColors.inputFill,
              valueColor: AlwaysStoppedAnimation(
                isOverGoal ? AppColors.spicyPaprika : AppColors.goldenOrange,
              ),
            ),
          ),
          if (goal.pendingDailyLimitMinutes != null) ...[
            const SizedBox(height: 10),
            Text(
              'New limit of ${_formatMinutes(goal.pendingDailyLimitMinutes as int)} takes effect tomorrow',
              style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppColors.darkCoffee),
            ),
        ],
      ],
      )
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
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
  late int _selectedMinutes = widget.currentMinutes;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final h = _selectedMinutes ~/ 60;
    final m = _selectedMinutes % 60;

    return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('EDIT DAILY GOAL', style: textTheme.labelLarge),
            const SizedBox(height: 8),
            Text('${h}h ${m.toString().padLeft(2, '0')}m', style: textTheme.headlineMedium?.copyWith(fontSize: 20)),
            Slider(
              value: _selectedMinutes.toDouble(),
              min: 15,
              max: 720,
              divisions: 47,
              activeColor: AppColors.spicyPaprika,
              onChanged: (value) => setState(() => _selectedMinutes = value.round()),
            ),
            Text(
              'This will take effect tomorrow, to keep your streak fair.',
              style: textTheme.bodyMedium?.copyWith(fontSize: 11, color: AppColors.darkCoffee),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'CONFIRM',
                    icon: Icons.check,
                    onPressed: () => widget.onConfirm(_selectedMinutes),
                    height: 40,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: widget.onCancel, child: const Text('Cancel')),
              ],
            ),
          ],
        )
    );
  }
}
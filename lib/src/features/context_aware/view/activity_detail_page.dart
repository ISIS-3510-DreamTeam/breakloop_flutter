import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';
import '../data/activity_catalog_data_source.dart';
import '../data/activity_log_repository_impl.dart';
import '../data/activity_repository_impl.dart';
import '../data/context_provider_impl.dart';
import '../data/interests_data_source.dart';
import '../data/location_data_source.dart';
import '../data/permissions_data_source.dart';
import '../data/weather_api.dart';
import '../data/weather_repository_impl.dart';
import '../model/activity_phase.dart';
import '../viewmodel/activity_detail_ui_state.dart';
import '../viewmodel/activity_detail_viewmodel.dart';
import 'category_style.dart';
import 'offline_header.dart';

class ActivityDetailPage extends StatelessWidget {
  final String activityId;
  //True when the user opened the activity from the suggestion card
  final bool fromSuggestion;

  const ActivityDetailPage({super.key, required this.activityId, required this.fromSuggestion});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final activityLogRepository = ActivityLogRepositoryImpl();
        return ActivityDetailViewModel(
          activityId,
          fromSuggestion,
          ActivityRepositoryImpl(ActivityCatalogDataSource()),
          activityLogRepository,
          ContextProviderImpl(
            InterestsDataSource(),
            activityLogRepository,
            WeatherRepositoryImpl(LocationDataSource(PermissionsDataSource()), WeatherApi()),
          ),
        );
      },
      child: const _ActivityDetailViewContent(),
    );
  }
}

class _ActivityDetailViewContent extends StatelessWidget {
  const _ActivityDetailViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ActivityDetailViewModel>();

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: Column(
        children: [
          const OfflineHeader(section: 'ACTIVITY'),
          Expanded(
            child: switch (vm.uiState) {
              ActivityDetailLoading() => const Center(child: CircularProgressIndicator(color: AppColors.spicyPaprika)),
              ActivityDetailNotFound() => _buildNotFound(context),
              ActivityDetailContent content => _buildContent(context, vm, content),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Activity not found', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          AppPill(label: '← Back', onTap: () => context.pop()),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ActivityDetailViewModel vm, ActivityDetailContent state) {
    final textTheme = Theme.of(context).textTheme;
    final activity = state.activity;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            AppPill(label: '← Back', onTap: () => context.pop()),
            const SizedBox(width: 12),
            Text('Activity Detail', style: textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          color: AppColors.headerBackground,
          shadowOffset: const Offset(0, 4),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkCoffee, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: AppColors.darkCoffee, offset: Offset(0, 4), blurRadius: 0),
                  ],
                ),
                child: Text(categoryEmoji(activity.category), style: const TextStyle(fontSize: 36)),
              ),
              const SizedBox(height: 16),
              Text(
                activity.title,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(fontSize: 18, letterSpacing: 0),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.snow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkCoffee, width: 1.5),
                ),
                child: Text(
                  categoryLabel(activity.category),
                  style: textTheme.labelLarge?.copyWith(fontSize: 11, letterSpacing: 0, color: AppColors.spicyPaprika),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                activity.prompt,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.darkCoffee.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildMetricCard(context, 'Recommended Time', '${activity.durationMin} min', AppColors.darkCoffee)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard(context, 'Hearth Reward', '+${activity.xp} XP', AppColors.spicyPaprika)),
          ],
        ),
        const SizedBox(height: 20),
        ..._buildPhaseSection(context, vm, state),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, Color valueColor) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      child: Column(
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.darkCoffee.withValues(alpha: 0.8))),
          const SizedBox(height: 6),
          Text(value, style: textTheme.labelLarge?.copyWith(fontSize: 20, letterSpacing: 0, color: valueColor)),
        ],
      ),
    );
  }

  //Action and timer according to the phase of the activity
  List<Widget> _buildPhaseSection(BuildContext context, ActivityDetailViewModel vm, ActivityDetailContent state) {
    final textTheme = Theme.of(context).textTheme;

    switch (state.phase) {
      case ActivityPhase.ready:
        return [
          _ActionButton(label: '✅ START & LOG ACTIVITY', onTap: vm.start),
        ];
      case ActivityPhase.running:
        final minutes = (state.remainingSeconds ~/ 60).toString().padLeft(2, '0');
        final seconds = (state.remainingSeconds % 60).toString().padLeft(2, '0');
        return [
          AppCard(
            color: Colors.white,
            shadowOffset: const Offset(0, 4),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text('IN PROGRESS', style: textTheme.labelLarge?.copyWith(fontSize: 12, color: AppColors.darkCoffee.withValues(alpha: 0.75))),
                  const SizedBox(height: 8),
                  Text('$minutes:$seconds', style: textTheme.headlineLarge?.copyWith(fontSize: 44, color: AppColors.spicyPaprika)),
                  const SizedBox(height: 8),
                  Text(
                    "Put your phone face down. You've got this.",
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 14, color: AppColors.darkCoffee.withValues(alpha: 0.8)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(label: "I'M DONE", onTap: vm.finish),
        ];
      case ActivityPhase.completed:
        return [
          AppCard(
            color: Colors.white,
            shadowOffset: const Offset(0, 4),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  Text('NICE WORK', style: textTheme.labelLarge?.copyWith(fontSize: 12, color: AppColors.fern)),
                  const SizedBox(height: 8),
                  Text(
                    '+${state.activity.xp} XP earned!',
                    style: textTheme.labelLarge?.copyWith(fontSize: 22, letterSpacing: 0, color: AppColors.fern),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ActionButton(label: 'BACK TO ACTIVITIES', onTap: () => context.pop()),
        ];
    }
  }
}

//Main action of the view, with the same hard shadow as the cards
class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.spicyPaprika,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkCoffee, width: 2.5),
          boxShadow: const [
            BoxShadow(color: AppColors.darkCoffee, offset: Offset(0, 4), blurRadius: 0),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16, color: AppColors.snow),
        ),
      ),
    );
  }
}

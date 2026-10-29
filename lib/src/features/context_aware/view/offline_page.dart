import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../data/activity_catalog_data_source.dart';
import '../data/activity_log_repository_impl.dart';
import '../data/activity_repository_impl.dart';
import '../data/context_provider_impl.dart';
import '../data/interests_data_source.dart';
import '../data/location_data_source.dart';
import '../data/permissions_data_source.dart';
import '../data/weather_api.dart';
import '../data/weather_repository_impl.dart';
import '../model/recommend_activity_use_case.dart';
import '../model/rules/default_scoring_rules.dart';
import '../viewmodel/offline_ui_state.dart';
import '../viewmodel/offline_viewmodel.dart';
import 'activity_card.dart';
import 'breakloop_chip.dart';
import 'category_chips.dart';
import 'offline_header.dart';
import 'suggested_card.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final permissionsDataSource = PermissionsDataSource();
        return OfflineViewModel(
          ActivityRepositoryImpl(ActivityCatalogDataSource()),
          ContextProviderImpl(
            InterestsDataSource(),
            ActivityLogRepositoryImpl(),
            WeatherRepositoryImpl(LocationDataSource(permissionsDataSource), WeatherApi()),
          ),
          const RecommendActivityUseCase(rules: DefaultScoringRules.all),
          permissionsDataSource,
        );
      },
      child: const _OfflineViewContent(),
    );
  }
}

class _OfflineViewContent extends StatelessWidget {
  const _OfflineViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OfflineViewModel>();

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: Column(
        children: [
          const OfflineHeader(section: 'OFFLINE'),
          Expanded(
            child: switch (vm.uiState) {
              OfflineLoading() => const Center(child: CircularProgressIndicator(color: AppColors.spicyPaprika)),
              OfflineContent content => _buildContent(context, vm, content),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, OfflineViewModel vm, OfflineContent state) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          color: AppColors.headerBackground,
          shadowOffset: const Offset(0, 4),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('WHAT WILL YOU DO OFFLINE?', style: textTheme.labelLarge?.copyWith(fontSize: 16, letterSpacing: 0.5)),
              const SizedBox(height: 6),
              Text(
                'Tangible alternatives to break the screen reflex.',
                style: textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.darkCoffee.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
        if (state.needsLocationPermission) ...[
          const SizedBox(height: 20),
          _buildLocationPermissionCard(context, vm),
        ],
        const SizedBox(height: 20),
        SuggestedCard(
          suggestion: state.suggestion,
          availableMin: state.availableMin,
          isWeatherAvailable: state.isWeatherAvailable,
          onTimeSelected: vm.onAvailableTimeSelected,
          onActivityTap: (id) => _openActivity(context, id, fromSuggestion: true),
        ),
        const SizedBox(height: 20),
        CategoryChips(
          selectedCategory: state.selectedCategory,
          onCategorySelected: vm.onCategorySelected,
        ),
        const SizedBox(height: 20),
        Text(
          'ALL ACTIVITIES',
          style: textTheme.labelLarge?.copyWith(fontSize: 12, letterSpacing: 0.5, color: AppColors.darkCoffee.withValues(alpha: 0.75)),
        ),
        const SizedBox(height: 12),
        for (final activity in state.activities) ...[
          ActivityCard(
            activity: activity,
            onTap: () => _openActivity(context, activity.id, fromSuggestion: false),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  //Invites the user to share the approximate location, so the suggestions can consider the weather
  Widget _buildLocationPermissionCard(BuildContext context, OfflineViewModel vm) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Want weather-aware suggestions?', style: textTheme.labelLarge?.copyWith(fontSize: 14, letterSpacing: 0)),
          const SizedBox(height: 4),
          Text(
            'We only use your approximate location to check the weather.',
            style: textTheme.bodyMedium?.copyWith(fontSize: 13, color: AppColors.darkCoffee.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 12),
          BreakLoopChip(label: 'Enable location', selected: true, onTap: vm.requestLocationPermission),
        ],
      ),
    );
  }

  //Child route of /offline, so the detail keeps the navBar
  void _openActivity(BuildContext context, String id, {required bool fromSuggestion}) {
    context.push('/offline/activity/$id?fromSuggestion=$fromSuggestion');
  }
}

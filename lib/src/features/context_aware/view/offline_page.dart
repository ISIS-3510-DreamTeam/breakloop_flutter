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
        Text('SCREEN-FREE SESSION', style: textTheme.labelSmall?.copyWith(color: AppColors.paprika700)),
        const SizedBox(height: 2),
        Text('What will you do offline?', style: textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(
          'How much time do you have right now?',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
        ),
        if (state.needsLocationPermission) ...[
          const SizedBox(height: 20),
          _buildLocationPermissionCard(context, vm),
        ],
        const SizedBox(height: 20),
        TimeSelector(
          availableMin: state.availableMin,
          onTimeSelected: vm.onAvailableTimeSelected,
        ),
        const SizedBox(height: 20),
        SuggestedCard(
          suggestion: state.suggestion,
          availableMin: state.availableMin,
          isWeatherAvailable: state.isWeatherAvailable,
          onActivityTap: (id) => _openActivity(context, id, fromSuggestion: true),
        ),
        const SizedBox(height: 20),
        Text('OR EXPLORE ALL ACTIVITIES', style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700)),
        const SizedBox(height: 12),
        CategoryChips(
          selectedCategory: state.selectedCategory,
          onCategorySelected: vm.onCategorySelected,
        ),
        for (final activity in state.activities) ...[
          const SizedBox(height: 12),
          ActivityCard(
            activity: activity,
            onTap: () => _openActivity(context, activity.id, fromSuggestion: false),
          ),
        ],
      ],
    );
  }

  //Invites the user to share the approximate location, so the suggestions can consider the weather
  Widget _buildLocationPermissionCard(BuildContext context, OfflineViewModel vm) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Want weather-aware suggestions?', style: textTheme.titleSmall),
          Text(
            'We only use your approximate location to check the weather.',
            style: textTheme.bodySmall?.copyWith(color: AppColors.neutral700),
          ),
          const SizedBox(height: 8),
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

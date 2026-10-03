import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/statistics_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';

class DeepStatsPage extends StatelessWidget {
  const DeepStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatisticsViewModel(),
      child: const _DeepStatsViewContent(),
    );
  }
}

class _DeepStatsViewContent extends StatelessWidget {
  const _DeepStatsViewContent();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StatisticsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.snow,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSubHeader(context),
                const SizedBox(height: 16),
                _buildMindfulUnlockCard(context, vm),
                const SizedBox(height: 16),
                _buildDailyPickupCard(context, vm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Barra de navegación superior (Botón ← Back y Título)
  Widget _buildSubHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        AppPill(
          label: '← Back',
          onTap: () => Navigator.maybePop(context),
        ),
        const SizedBox(width: 12),
        Text(
          'Detailed Statistics',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.darkCoffee,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Tarjeta 1: Mindful Unlock Intentionality
  Widget _buildMindfulUnlockCard(BuildContext context, StatisticsViewModel vm) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MINDFUL UNLOCK INTENTIONALITY',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.spicyPaprika,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Círculo de porcentaje
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.spicyPaprika,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${vm.mindfulPercentage}%',
                    style: textTheme.headlineMedium?.copyWith(
                      color: AppColors.spicyPaprika,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vm.mindfulPercentage}% intentional unlocks',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.darkCoffee,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Only ${vm.impulsivePercentage}% were impulsive reflex pick-ups.',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tarjeta 2: Daily Pickup Count (Conectada al ViewModel)
  Widget _buildDailyPickupCard(BuildContext context, StatisticsViewModel vm) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: Colors.white,
      shadowOffset: const Offset(0, 4),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DAILY PICKUP COUNT',
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.spicyPaprika,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${vm.dailyPickups}',
                style: textTheme.headlineLarge?.copyWith(
                  color: AppColors.darkCoffee,
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'pickups',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.darkCoffee,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                vm.baselineText,
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.fern,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Average interval between phone checks: ${vm.avgIntervalMinutes} minutes.',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../data/activity_catalog_data_source.dart';
import '../data/activity_log_repository_impl.dart';
import '../data/activity_repository_impl.dart';
import '../data/context_provider_impl.dart';
import '../data/interests_data_source.dart';
import '../data/location_data_source.dart';
import '../data/permissions_data_source.dart';
import '../data/place_data_source.dart';
import '../data/suggestion_interaction_repository_impl.dart';
import '../data/weather_api.dart';
import '../data/weather_repository_impl.dart';
import '../model/activity_phase.dart';
import '../model/offline_activity.dart';
import '../viewmodel/activity_detail_ui_state.dart';
import '../viewmodel/activity_detail_viewmodel.dart';
import 'category_style.dart';

class ActivityDetailPage extends StatelessWidget {
  final String activityId;
  //True when the user opened the activity from the suggestion card
  final bool fromSuggestion;
  //Interaction of the Offline view that opened the activity, or null
  final String? interactionId;

  const ActivityDetailPage({super.key, required this.activityId, required this.fromSuggestion, this.interactionId});

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
          PlaceDataSource(),
          SuggestionInteractionRepositoryImpl(),
          interactionId,
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
          Text('Activity not found', style: Theme.of(context).textTheme.titleMedium),
          TextButton(onPressed: () => context.pop(), child: const Text('Back')),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ActivityDetailViewModel vm, ActivityDetailContent state) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.darkCoffee),
              tooltip: 'Back',
              onPressed: () => context.pop(),
            ),
            Text('ACTIVITY', style: textTheme.labelSmall?.copyWith(color: AppColors.neutral700)),
          ],
        ),
        const SizedBox(height: 20),
        _buildHero(context, state.activity),
        const SizedBox(height: 20),
        ..._buildPhaseSection(context, vm, state),
      ],
    );
  }

  //Category badge, title, prompt, duration and XP of the activity
  Widget _buildHero(BuildContext context, OfflineActivity activity) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        _PixelBadge(
          color: categoryColor(activity.category),
          size: 112,
          borderRadius: BorderRadius.circular(28),
          child: Icon(categoryIcon(activity.category), size: 56, color: AppColors.darkCoffee),
        ),
        const SizedBox(height: 12),
        Text(
          categoryLabel(activity.category).toUpperCase(),
          style: textTheme.labelSmall?.copyWith(color: AppColors.paprika700),
        ),
        const SizedBox(height: 12),
        Text(activity.title, textAlign: TextAlign.center, style: textTheme.headlineMedium),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            activity.prompt,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DetailPill(icon: Icons.timer_outlined, text: '${activity.durationMin} MIN', color: AppColors.darkCoffee),
            const SizedBox(width: 10),
            _DetailPill(icon: Icons.bolt_outlined, text: '+${activity.xp} XP', color: AppColors.fern),
          ],
        ),
      ],
    );
  }

  //Action and timer according to the phase of the activity
  List<Widget> _buildPhaseSection(BuildContext context, ActivityDetailViewModel vm, ActivityDetailContent state) {
    final textTheme = Theme.of(context).textTheme;

    switch (state.phase) {
      case ActivityPhase.ready:
        final blockedBy = state.blockedBy;
        //Only one activity at a time, like in the Kotlin app
        if (blockedBy != null) {
          return [
            AppCard(
              color: AppColors.golden100,
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 28, color: AppColors.paprika700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "You're already doing ${blockedBy.title}. Finish it before starting a new one.",
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppButton(
              label: 'Go to ${blockedBy.title}',
              //Replaces this detail, so back returns to the list
              onPressed: () => context.pushReplacement('/offline/activity/${blockedBy.activityId}?fromSuggestion=false'),
            ),
          ];
        }
        return [
          Text(
            'Put your phone away and give this your full attention.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
          ),
          const SizedBox(height: 12),
          AppButton(label: 'Start & Log Activity', onPressed: vm.start),
        ];
      case ActivityPhase.running:
        final total = state.activity.durationMin * 60;
        return [
          Center(
            child: _CircularTimer(
              remainingFraction: (state.remainingSeconds / total).clamp(0.0, 1.0),
              remainingSeconds: state.remainingSeconds,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Put your phone face down. You've got this.",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.neutral700),
          ),
          const SizedBox(height: 16),
          AppButton(label: "I'm done", onPressed: vm.finish),
        ];
      case ActivityPhase.completed:
        return [
          const Center(
            child: _PixelBadge(
              color: AppColors.fern100,
              size: 96,
              circle: true,
              child: Icon(Icons.check_circle_outline, size: 52, color: AppColors.fern),
            ),
          ),
          const SizedBox(height: 16),
          Text('NICE WORK', textAlign: TextAlign.center, style: textTheme.labelSmall?.copyWith(color: AppColors.fern)),
          const SizedBox(height: 16),
          Text('+${state.activity.xp} XP earned!', textAlign: TextAlign.center, style: textTheme.headlineSmall),
          const SizedBox(height: 16),
          AppButton(label: 'Back to activities', onPressed: () => context.pop()),
        ];
    }
  }
}

//Badge with a border and a solid shadow, the same pixel-art style of the cards
class _PixelBadge extends StatelessWidget {
  final Color color;
  final double size;
  final BorderRadius? borderRadius;
  final bool circle;
  final Widget child;

  const _PixelBadge({
    required this.color,
    required this.size,
    this.borderRadius,
    this.circle = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : borderRadius,
        border: Border.all(color: AppColors.darkCoffee, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.darkCoffee, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: child,
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _DetailPill({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.darkCoffee, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

//Round timer with a segmented ring, like the health bars of retro games
class _CircularTimer extends StatelessWidget {
  final double remainingFraction;
  final int remainingSeconds;

  const _CircularTimer({required this.remainingFraction, required this.remainingSeconds});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');

    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.golden100,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.darkCoffee, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.darkCoffee, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: CustomPaint(painter: _SegmentedRingPainter(remainingFraction)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('IN PROGRESS', style: textTheme.labelSmall?.copyWith(color: AppColors.paprika700)),
              const SizedBox(height: 4),
              Text('$minutes:$seconds', style: textTheme.displayMedium),
            ],
          ),
        ],
      ),
    );
  }
}

//Draws the gray track and the remaining time as dashes of 10 with gaps of 5, starting at the top
class _SegmentedRingPainter extends CustomPainter {
  final double remainingFraction;

  _SegmentedRingPainter(this.remainingFraction);

  static const _stroke = 16.0;
  static const _dash = 10.0;
  static const _gap = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(_stroke / 2, _stroke / 2, size.width - _stroke, size.height - _stroke);
    final radius = rect.width / 2;
    _drawDashes(canvas, rect, radius, 2 * pi, AppColors.neutral100);
    _drawDashes(canvas, rect, radius, 2 * pi * remainingFraction, AppColors.spicyPaprika);
  }

  void _drawDashes(Canvas canvas, Rect rect, double radius, double sweep, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;
    //Dash and gap lengths converted to angles of the circle
    final dashAngle = _dash / radius;
    final gapAngle = _gap / radius;
    for (var angle = 0.0; angle < sweep; angle += dashAngle + gapAngle) {
      canvas.drawArc(rect, -pi / 2 + angle, min(dashAngle, sweep - angle), false, paint);
    }
  }

  @override
  bool shouldRepaint(_SegmentedRingPainter oldDelegate) => oldDelegate.remainingFraction != remainingFraction;
}

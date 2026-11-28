import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodel/focus_viewmodel.dart';

class FocusRecoveryDialog extends StatelessWidget {
  final FocusViewModel viewModel;
  final VoidCallback onRecoveryResolved;
  final String hourglassAssetPath;

  const FocusRecoveryDialog({
    super.key,
    required this.viewModel,
    required this.onRecoveryResolved,
    this.hourglassAssetPath = 'assets/icons/nav/focus_selected.svg',
  });

  double _calculateProgress(dynamic session, dynamic uiState) {
    int? totalSeconds;

    for (final getter in [
      () => session.totalSeconds,
      () => session.durationSeconds,
      () => session.selectedDurationMinutes * 60,
      () => session.durationMinutes * 60,
      () => uiState.selectedDurationMinutes * 60,
    ]) {
      try {
        final value = getter();
        if (value is int && value > 0) {
          totalSeconds = value;
          break;
        }
      } catch (_) {}
    }

    if (totalSeconds == null || totalSeconds <= 0) {
      return 0.0;
    }

    int? elapsedSeconds;
    try {
      final elapsed = session.elapsedSeconds;
      if (elapsed is int && elapsed >= 0) {
        elapsedSeconds = elapsed;
      }
    } catch (_) {}

    if (elapsedSeconds == null) {
      try {
        final remaining = session.remainingSeconds;
        if (remaining is int && remaining >= 0) {
          elapsedSeconds = totalSeconds - remaining;
        }
      } catch (_) {}
    }

    if (elapsedSeconds == null) {
      return 0.0;
    }

    return (elapsedSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  String _extractFocusGoal(dynamic session, dynamic uiState) {
    try {
      final goal = session.focusGoal;
      if (goal is String && goal.trim().isNotEmpty) {
        return goal.trim();
      }
    } catch (_) {}

    try {
      final goal = uiState.focusGoal;
      if (goal is String && goal.trim().isNotEmpty) {
        return goal.trim();
      }
    } catch (_) {}

    return '';
  }

  Widget _buildConnectivityBanner(TextTheme textTheme) {
    if (viewModel.isOffline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.spicyPaprika.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'No internet connection',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.spicyPaprika,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (viewModel.showRestoredBanner) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.spicyPaprika.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'Internet connection restored',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.spicyPaprika,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final session = viewModel.recoverySession;

        if (session == null) {
          return const SizedBox.shrink();
        }

        final uiState = viewModel.state;
        final progress = _calculateProgress(session, uiState);
        final percentage = (progress * 100).round();
        final focusGoal = _extractFocusGoal(session, uiState);
        final textTheme = Theme.of(context).textTheme;

        return Dialog(
          backgroundColor: const Color(0xFFFAF3EC),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Banner dinámico de conectividad
                _buildConnectivityBanner(textTheme),

                // Ícono del reloj + badge de exclamación
                SizedBox(
                  width: 84,
                  height: 76,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        hourglassAssetPath,
                        width: 58,
                        height: 58,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint(
                            'Error cargando SVG ($hourglassAssetPath): $error',
                          );
                          return const Icon(
                            Icons.hourglass_empty_rounded,
                            size: 52,
                            color: AppColors.darkCoffee,
                          );
                        },
                      ),
                      Positioned(
                        top: 0,
                        right: 4,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.spicyPaprika,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Título
                Text(
                  'FOCUS INTERRUPTED',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.darkCoffee,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtítulo
                Text(
                  'Your previous focus session was interrupted. Would you like to continue?',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkCoffee.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 24),

                // Etiqueta SESSION PROGRESS
                Text(
                  'SESSION PROGRESS',
                  textAlign: TextAlign.center,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.darkCoffee.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),

                const SizedBox(height: 10),

                // Barra de progreso con borde oscuro
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.darkCoffee,
                      width: 1.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          color: AppColors.spicyPaprika,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Porcentaje completado
                Text(
                  '$percentage% completed',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkCoffee.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (focusGoal.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Target: $focusGoal',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.darkCoffee.withValues(alpha: 0.75),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Botón principal: CONTINUE
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.spicyPaprika,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: const BorderSide(
                          color: AppColors.darkCoffee,
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: () async {
                      await viewModel.continueRecoveredSession();
                      onRecoveryResolved();
                    },
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Botón secundario: START A NEW SESSION
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.darkCoffee,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(
                        color: AppColors.darkCoffee,
                        width: 1.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () async {
                      await viewModel.restartRecoveredSession();
                      onRecoveryResolved();
                    },
                    child: const Text(
                      'START A NEW SESSION',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Botón terciario: ABANDON SESSION
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.spicyPaprika,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: const BorderSide(
                        color: AppColors.spicyPaprika,
                        width: 1.8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: () async {
                      await viewModel.finishRecoveredSession();
                      onRecoveryResolved();
                    },
                    child: const Text(
                      'ABANDON SESSION',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodel/focus_viewmodel.dart';

class FocusCompletionDialog extends StatelessWidget {
  final FocusViewModel viewModel;
  final VoidCallback onContinue;
  final String hourglassAssetPath;

  const FocusCompletionDialog({
    super.key,
    required this.viewModel,
    required this.onContinue,
    this.hourglassAssetPath = 'assets/icons/nav/focus_selected.svg',
  });

  String _formatClockDuration(int totalSeconds) {
    final safeSeconds = totalSeconds < 0 ? 0 : totalSeconds;
    final minutes = safeSeconds ~/ 60;
    final seconds = safeSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  int _resolveXp(dynamic session) {
    try {
      final xp = session.xpEarned;
      if (xp is int && xp > 0) return xp;
    } catch (_) {}
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final session = viewModel.completionSession;

    if (session == null) {
      return const SizedBox.shrink();
    }

    final textTheme = Theme.of(context).textTheme;
    final xpAmount = _resolveXp(session);

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
        padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono del reloj + badge con check
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
                      return const Icon(
                        Icons.hourglass_bottom_rounded,
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
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Título
            Text(
              'FOCUS COMPLETED!',
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
              'Great job! You completed your focus session.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.darkCoffee.withValues(alpha: 0.72),
                height: 1.35,
              ),
            ),

            const SizedBox(height: 24),

            // Etiqueta FOCUS TIME
            Text(
              'FOCUS TIME',
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.darkCoffee.withValues(alpha: 0.82),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),

            const SizedBox(height: 6),

            // Tiempo en formato MM:SS (ej. 25:00)
            Text(
              _formatClockDuration(session.duration),
              textAlign: TextAlign.center,
              style: textTheme.displaySmall?.copyWith(
                color: AppColors.darkCoffee,
                fontWeight: FontWeight.w800,
                fontSize: 36,
              ),
            ),

            const SizedBox(height: 8),

            // XP ganada
            Text(
              '+$xpAmount XP',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.spicyPaprika,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: 28),

            // Botón principal: BACK TO FOCUS
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
                onPressed: () {
                  viewModel.dismissCompletionDialog();
                  onContinue();
                },
                child: const Text(
                  'BACK TO FOCUS',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
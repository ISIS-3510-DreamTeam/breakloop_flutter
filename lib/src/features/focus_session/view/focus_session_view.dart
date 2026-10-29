import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../viewmodel/focus_session_ui_state.dart';
import '../viewmodel/focus_viewmodel.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_pill.dart';

class FocusScreen extends StatefulWidget {
  /// ViewModel that controls the focus session
  final FocusViewModel viewModel;

  const FocusScreen({
    super.key,
    required this.viewModel,
  });

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  // controllers for the text fields
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _customDurationController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    // Load the current values from the ViewModel
    _goalController.text = widget.viewModel.state.focusGoal;
    _customDurationController.text =
        widget.viewModel.state.customDurationMinutes.toString();
  }

  @override
  void dispose() {
    // Dispose the text controllers when the screen is removed
    _goalController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // rtebuild the screen when the ViewModel state changes
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final state = widget.viewModel.state;

        return Scaffold(
          backgroundColor: AppColors.snow,
          body: Column(
            children: [
              // Show the header only before the session starts
              if (!state.isTimerRunning) _buildHeader(context),

              Expanded(
                // Show the active session or the setup screen
                child: state.isTimerRunning
                    ? ActiveFocusContent(
                        state: state,
                        onStopFocus: widget.viewModel.cancelSession,
                      )
                    : FocusSetupContent(
                        state: state,
                        goalController: _goalController,
                        customDurationController:
                            _customDurationController,
                        viewModel: widget.viewModel,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Builds the header shown before starting a focus session
  Widget _buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.headerBackground,
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkCoffee,
            width: 3,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/board_logo.png',
                    width: 56,
                    height: 56,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BREAKLOOP',
                        style: textTheme.titleLarge?.copyWith(
                          color: AppColors.spicyPaprika,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'FOCUS SETUP',
                        style: textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          color: AppColors.darkCoffee,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppPill(label: '🛡 Shield Test'),
                  SizedBox(width: 12),
                  AppPill(label: '🔥 12d'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Focus session setup screen

class FocusSetupContent extends StatelessWidget {
  final FocusSessionUiState state;
  final TextEditingController goalController;
  final TextEditingController customDurationController;
  final FocusViewModel viewModel;

  const FocusSetupContent({
    super.key,
    required this.state,
    required this.goalController,
    required this.customDurationController,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Introduction card
        AppCard(
          color: Colors.white,
          shadowOffset: const Offset(0, 4),
          padding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.darkCoffee,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.snow,
                ),
                child: Image.asset(
                  'assets/images/hourglass.png',
                  width: 35,
                  height: 35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ready to Focus?',
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.darkCoffee,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select your duration and choose your commitment.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.darkCoffee,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Session duration
        Text(
          'SESSION LENGTH',
          style: textTheme.labelLarge?.copyWith(
            color: AppColors.darkCoffee,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: CustomDurationButton(
                text: '25m',
                selected: state.selectedDurationMinutes == 25 &&
                    !state.isCustomSelected,
                onTap: () => viewModel.updatePresetDuration(25),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomDurationButton(
                text: '45m',
                selected: state.selectedDurationMinutes == 45 &&
                    !state.isCustomSelected,
                onTap: () => viewModel.updatePresetDuration(45),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomDurationButton(
                text: '60m',
                selected: state.selectedDurationMinutes == 60 &&
                    !state.isCustomSelected,
                onTap: () => viewModel.updatePresetDuration(60),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomDurationButton(
                text: 'Custom',
                selected: state.isCustomSelected,
                onTap: () => viewModel.updateCustomDuration(
                  int.tryParse(customDurationController.text) ?? 25,
                ),
              ),
            ),
          ],
        ),

        // Show the custom duration field only when Custom is selected
        if (state.isCustomSelected) ...[
          const SizedBox(height: 12),
          TextField(
            controller: customDurationController,
            keyboardType: TextInputType.number,
            style: textTheme.labelLarge?.copyWith(
              color: AppColors.darkCoffee,
              fontWeight: FontWeight.normal,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'Custom duration',
              hintText: 'Enter minutes',
              suffixText: 'min',
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(
                  color: AppColors.spicyPaprika,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              final duration = int.tryParse(value);

              if (duration != null && duration > 0) {
                viewModel.updateCustomDuration(duration);
              }
            },
          ),
        ],

        const SizedBox(height: 20),

        // Optional focus goal
        AppCard(
          color: Colors.white,
          shadowOffset: const Offset(0, 4),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOCUS GOAL (OPTIONAL)',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.darkCoffee,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.darkCoffee.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Text(
                      '🎯',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: goalController,
                        style: textTheme.labelLarge?.copyWith(
                          color: AppColors.darkCoffee,
                          fontWeight: FontWeight.normal,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Study Economics Reading',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: viewModel.setFocusGoal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Soundscape options
        AppCard(
          color: Colors.white,
          shadowOffset: const Offset(0, 4),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COZY SOUNDSCAPE',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.darkCoffee,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SoundOptionButton(
                      emoji: '🔥',
                      label: 'Hearth\nCrackle',
                      selected:
                          state.activeSoundscape == Soundscape.waves,
                      onTap: () =>
                          viewModel.selectSoundscape(Soundscape.waves),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SoundOptionButton(
                      emoji: '🌧️',
                      label: 'Soft Rain',
                      selected:
                          state.activeSoundscape == Soundscape.rain,
                      onTap: () =>
                          viewModel.selectSoundscape(Soundscape.rain),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SoundOptionButton(
                      emoji: '🤫',
                      label: 'Pure\nSilence',
                      selected:
                          state.activeSoundscape == Soundscape.silence,
                      onTap: () =>
                          viewModel.selectSoundscape(Soundscape.silence),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // App blocker option
        AppCard(
          color: Colors.white,
          shadowOffset: const Offset(0, 4),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                '🛡️',
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Shield Active',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.darkCoffee,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '10-second breath challenge on Instagram/TikTok',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.darkCoffee.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: state.isAppBlockerActive
                      ? const Color(0xFFE8F5E9)
                      : Colors.grey.shade200,
                  border: Border.all(
                    color: state.isAppBlockerActive
                        ? Colors.green
                        : Colors.grey,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: GestureDetector(
                  onTap: () => viewModel.toggleAppBlocker(
                    !state.isAppBlockerActive,
                  ),
                  child: Text(
                    state.isAppBlockerActive ? 'ON' : 'OFF',
                    style: textTheme.labelMedium?.copyWith(
                      color: state.isAppBlockerActive
                          ? Colors.green.shade800
                          : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Show an error message if there is one
        if (state.errorMessage != null) ...[
          Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Start focus session button
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.spicyPaprika,
            foregroundColor: Colors.white,
            elevation: 4,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(
                color: AppColors.darkCoffee,
                width: 2,
              ),
            ),
          ),
          onPressed: viewModel.startFocusSession,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/hourglass.png',
                width: 25,
                height: 25,
              ),
              const SizedBox(width: 8),
              Text(
                'START FOCUS',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// Active focus session


class ActiveFocusContent extends StatelessWidget {
  final FocusSessionUiState state;
  final VoidCallback onStopFocus;

  const ActiveFocusContent({
    super.key,
    required this.state,
    required this.onStopFocus,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Convert the remaining seconds into minutes and seconds
    final minutes = state.remainingSeconds ~/ 60;
    final seconds = state.remainingSeconds % 60;

    final timeText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    // Calculate the timer progress
    final totalSeconds = state.selectedDurationMinutes * 60;
    final progress = totalSeconds > 0
        ? (state.elapsedSeconds / totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 16.0,
        ),
        child: Column(
          children: [
            // Top bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FOCUS SPRINT',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.spicyPaprika,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: AppColors.spicyPaprika,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '🛡️',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'DO NOT DISTURB',
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.spicyPaprika,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Main focus card
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6ED),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.darkCoffee,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/hourglass.png',
                    width: 55,
                    height: 55,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ᴗ •',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.darkCoffee,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MINDFUL FOCUS',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.spicyPaprika,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Large timer
            Text(
              timeText,
              style: textTheme.displayLarge?.copyWith(
                color: AppColors.darkCoffee,
                fontWeight: FontWeight.bold,
                fontSize: 64,
              ),
            ),

            const SizedBox(height: 12),

            // Show the focus goal if the user entered one
            if (state.focusGoal.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.darkCoffee,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'Target: ${state.focusGoal}',
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.darkCoffee,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Progress bar
            Container(
              width: 220,
              height: 16,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.darkCoffee,
                  width: 2,
                ),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  color: AppColors.spicyPaprika.withOpacity(0.7),
                ),
              ),
            ),

            const Spacer(),

            // End the session early
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkCoffee,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onStopFocus,
              child: Text(
                'END SESSION EARLY',
                style: textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Reusable UI components


class CustomDurationButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const CustomDurationButton({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.spicyPaprika
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.darkCoffee,
            width: 2,
          ),
        ),
        child: Text(
          text,
          style: textTheme.labelLarge?.copyWith(
            color: selected
                ? Colors.white
                : AppColors.darkCoffee,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class SoundOptionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SoundOptionButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.headerBackground
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.spicyPaprika
                : AppColors.darkCoffee.withOpacity(0.3),
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.darkCoffee,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
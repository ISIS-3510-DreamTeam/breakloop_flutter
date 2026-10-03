enum Soundscape { silence, rain, forest, waves, whiteNoise }

class FocusSessionUiState {
  /// Selected duration for the focus session
  final int selectedDurationMinutes;

  // Custom duration entered by the user
  final int customDurationMinutes;

  // Indicates if the custom duration is selected
  final bool isCustomSelected;
  // Goal written by the user for the focus session
  final String focusGoal;

  // Soundscape currently selected
  final Soundscape activeSoundscape;

  // Indicates if the app blocker is active
  final bool isAppBlockerActive;

  // Indicates if the timer is currently running
  final bool isTimerRunning;

  /// Indicates if the timer is paused
  final bool isTimerPaused;

  // Seconds remaining in the timer
  final int remainingSeconds;

  // Seconds elapsed since the session started
  final int elapsedSeconds;

  // Indicates if the session is being synchronized
  final bool isSyncing;

  // Stores an error message if something goes wrong
  final String? errorMessage;

  const FocusSessionUiState({
    this.selectedDurationMinutes = 25,
    this.customDurationMinutes = 25,
    this.isCustomSelected = false,
    this.focusGoal = '',
    this.activeSoundscape = Soundscape.silence,
    this.isAppBlockerActive = false,
    this.isTimerRunning = false,
    this.isTimerPaused = false,
    this.remainingSeconds = 0,
    this.elapsedSeconds = 0,
    this.isSyncing = false,
    this.errorMessage,
  });

  // Creates a new state while keeping the values that were not changed
  FocusSessionUiState copyWith({
    int? selectedDurationMinutes,
    int? customDurationMinutes,
    bool? isCustomSelected,
    String? focusGoal,
    Soundscape? activeSoundscape,
    bool? isAppBlockerActive,
    bool? isTimerRunning,
    bool? isTimerPaused,
    int? remainingSeconds,
    int? elapsedSeconds,
    bool? isSyncing,
    String? errorMessage,
  }) {
    return FocusSessionUiState(
      selectedDurationMinutes:
          selectedDurationMinutes ?? this.selectedDurationMinutes,
      customDurationMinutes:
          customDurationMinutes ?? this.customDurationMinutes,
      isCustomSelected:
          isCustomSelected ?? this.isCustomSelected,
      focusGoal:
          focusGoal ?? this.focusGoal,
      activeSoundscape:
          activeSoundscape ?? this.activeSoundscape,
      isAppBlockerActive:
          isAppBlockerActive ?? this.isAppBlockerActive,
      isTimerRunning:
          isTimerRunning ?? this.isTimerRunning,
      isTimerPaused:
          isTimerPaused ?? this.isTimerPaused,
      remainingSeconds:
          remainingSeconds ?? this.remainingSeconds,
      elapsedSeconds:
          elapsedSeconds ?? this.elapsedSeconds,
      isSyncing:
          isSyncing ?? this.isSyncing,
      errorMessage:
          errorMessage,
    );
  }
}
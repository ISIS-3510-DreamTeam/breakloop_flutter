import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/focus_session_repository.dart';
import '../model/focus_session_model.dart';
import 'focus_session_ui_state.dart';

class FocusViewModel extends ChangeNotifier {
  // Handles saving and syncing focus sessions
  final FocusSessionRepository _repository;

  // Handles the current authenticated user
  final FirebaseAuth _auth;

  // Stores the current state of the focus session
  FocusSessionUiState _state = const FocusSessionUiState();

  // Provides the current state to the View
  FocusSessionUiState get state => _state;

  // Timer used to update the focus session every second
  Timer? _timer;

  // ID of the current focus session
  String? _currentSessionId;

  // Time when the current session started
  DateTime? _sessionStartTimestamp;

  FocusViewModel({
    FocusSessionRepository? repository,
    FirebaseAuth? auth,
  })  : _repository = repository ?? FocusSessionRepository(),
        _auth = auth ?? FirebaseAuth.instance;

  // Updates the selected preset duration
  void updatePresetDuration(int minutes) {
    _state = _state.copyWith(
      selectedDurationMinutes: minutes,
      isCustomSelected: false,
      errorMessage: null,
    );
    notifyListeners();
  }

  /// Updates the custom duration entered by the user
  void updateCustomDuration(int minutes) {
    _state = _state.copyWith(
      customDurationMinutes: minutes,
      selectedDurationMinutes: minutes,
      isCustomSelected: true,
      errorMessage: null,
    );
    notifyListeners();
  }

  // Updates the focus goal
  void setFocusGoal(String goal) {
    _state = _state.copyWith(
      focusGoal: goal,
      errorMessage: null,
    );
    notifyListeners();
  }

  // Changes the selected soundscape
  void selectSoundscape(Soundscape soundscape) {
    _state = _state.copyWith(activeSoundscape: soundscape);
    notifyListeners();
  }

  // enables or disables the app blocker
  void toggleAppBlocker(bool enabled) {
    _state = _state.copyWith(isAppBlockerActive: enabled);
    notifyListeners();
  }

  // Starts a new focus session
  void startFocusSession() {
    final duration = _state.selectedDurationMinutes;

    // Check that the selected duration is valid
    if (duration <= 0) {
      _state = _state.copyWith(
        errorMessage: 'Selecciona una duración válida',
      );
      notifyListeners();
      return;
    }

    // Check that the user is logged in
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _state = _state.copyWith(
        errorMessage:
            'Debes iniciar sesión para comenzar una sesión de foco',
      );
      notifyListeners();
      return;
    }

    // Cancel any previous timer
    _timer?.cancel();

    // Create an ID and save the start time for this session
    _currentSessionId =
        DateTime.now().millisecondsSinceEpoch.toString();
    _sessionStartTimestamp = DateTime.now();

    final totalSeconds = duration * 60;

    // Update the state when the session starts
    _state = _state.copyWith(
      isTimerRunning: true,
      isTimerPaused: false,
      remainingSeconds: totalSeconds,
      elapsedSeconds: 0,
      errorMessage: null,
    );
    notifyListeners();

    _runTimerLoop();
  }

  // ujpdates the timer every second
  void _runTimerLoop() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        // Do not update the timer while it is paused
        if (_state.isTimerPaused) return;

        if (_state.remainingSeconds > 0) {
          _state = _state.copyWith(
            remainingSeconds: _state.remainingSeconds - 1,
            elapsedSeconds: _state.elapsedSeconds + 1,
          );
          notifyListeners();
        } else {
          // Finish the session when the timer reaches zero
          _completeFocusSession();
        }
      },
    );
  }

  // Pauses the current session
  void pauseSession() {
    if (!_state.isTimerRunning) return;

    _state = _state.copyWith(isTimerPaused: true);
    notifyListeners();
  }

  // Resumes the current session
  void resumeSession() {
    if (!_state.isTimerRunning) return;

    _state = _state.copyWith(isTimerPaused: false);
    notifyListeners();
  }

  // Cancels the current session
  void cancelSession() {
    if (!_state.isTimerRunning) return;

    _saveSessionToStorage(SessionStatus.abandoned);
    _resetTimerState();
  }

  // Completes the current session
  void _completeFocusSession() {
    _saveSessionToStorage(SessionStatus.completed);
    _resetTimerState();
  }

  // Saves the session locally and tries to sync it with Firestore
  Future<void> _saveSessionToStorage(SessionStatus status) async {
    final sessionId = _currentSessionId;
    final startTime = _sessionStartTimestamp;
    final userId = _auth.currentUser?.uid;

    // Check that the required session information exists
    if (sessionId == null || startTime == null || userId == null) {
      _state = _state.copyWith(
        errorMessage: 'Error al registrar la sesión',
      );
      notifyListeners();
      return;
    }

    // Create the session model
    final newSession = FocusSessionModel(
      sessionId: sessionId,
      userId: userId,
      startedAt: startTime,
      durationSeconds: _state.selectedDurationMinutes * 60,
      sessionType: SessionType.pomodoro,
      sessionStatus: status,
      earnedXp: status == SessionStatus.completed
          ? _state.selectedDurationMinutes * 2
          : 0,
      isSynced: false,
    );

    try {
      // Save the session locally
      await _repository.saveSessionLocally(newSession);

      // Start cloud synchronization
      _state = _state.copyWith(isSyncing: true);
      notifyListeners();

      await _repository.syncUnsyncedSessions();
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'No se pudo sincronizar con Firestore',
      );
    } finally {
      // Finish the synchronization state
      _state = _state.copyWith(isSyncing: false);
      notifyListeners();
    }
  }

  // resets the timer and current session information
  void _resetTimerState() {
    _timer?.cancel();
    _timer = null;
    _currentSessionId = null;
    _sessionStartTimestamp = null;

    _state = _state.copyWith(
      isTimerRunning: false,
      isTimerPaused: false,
      remainingSeconds: 0,
      elapsedSeconds: 0,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel the timer when the ViewModel is removed
    _timer?.cancel();
    super.dispose();
  }
}
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/focus_session_repository.dart';
import '../model/focus_session_model.dart';
import '../model/soundscape_service.dart' ;
import 'focus_session_ui_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FocusViewModel extends ChangeNotifier {
  // Handles saving and syncing focus sessions
  final FocusSessionRepository _repository;

  // Handles the current authenticated user
  final FirebaseAuth _auth;

  final SoundscapeService _soundscapeService;

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

    // Stores the current session being tracked
  FocusSessionModel? _currentSession;

  // Stores the last elapsed time persisted locally
  int _lastPersistedElapsedSeconds = 0;

  // Stores the session waiting for user recovery
  FocusSessionModel? _recoverySession;

  FocusSessionModel? get recoverySession => _recoverySession;


  // Stores the session waiting for completion confirmation
FocusSessionModel? _completionSession;

FocusSessionModel? get completionSession => _completionSession;

  // StreamSubscription para el control de conectividad a internet
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  bool _showRestoredBanner = false;
  bool get showRestoredBanner => _showRestoredBanner;

  FocusViewModel({
    FocusSessionRepository? repository,
    FirebaseAuth? auth,
    SoundscapeService? soundscapeService,
  })  : _repository = repository ?? FocusSessionRepository(),
        _auth = auth ?? FirebaseAuth.instance,
        _soundscapeService = soundscapeService ?? SoundscapeService() {
   //INTERNET
   _initConnectivityListener();
  }

  // Inicializa el detector de red
  void _initConnectivityListener() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final bool hasConnection = !results.contains(ConnectivityResult.none);

      if (!hasConnection) {
        _isOffline = true;
        _showRestoredBanner = false;
        notifyListeners();
      } else {
        if (_isOffline) {
          _isOffline = false;
          _showRestoredBanner = true;
          notifyListeners();

          Future.delayed(const Duration(seconds: 3), () {
            _showRestoredBanner = false;
            notifyListeners();
          });
        }
      }
    });
  }

  // Updates the selected preset duration
  void updatePresetDuration(int minutes) {
    _state = _state.copyWith(
      selectedDurationMinutes: minutes,
      isCustomSelected: false,
      errorMessage: null,
    );
    notifyListeners();
  }

  /// Updates the custom duration entered by the user with validation
  void updateCustomDuration(int minutes, {bool validateRange = false}) {
    // Validar si es menor o igual a 0
    if (minutes <= 0) {
      _state = _state.copyWith(
        isCustomSelected: true,
        errorMessage: 'Enter a whole number greater than 0.',
      );
      notifyListeners();
      return;
    }

    // Validar si excede los 120 minutos
    if (minutes > 120) {
      _state = _state.copyWith(
        isCustomSelected: true,
        errorMessage: "Pomodoro, it's all about taking breaks!",
      );
      notifyListeners();
      return;
    }

    // Si todo está bien, actualiza la duración y limpia el error
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

//CACHE
  // Changes the selected soundscape and plays it immediately
  Future<void> selectSoundscape(Soundscape soundscape) async {
    _state = _state.copyWith(activeSoundscape: soundscape);
    notifyListeners();

    await _soundscapeService.playSoundscape(soundscape);
  }

  // enables or disables the app blocker
  void toggleAppBlocker(bool enabled) {
    _state = _state.copyWith(isAppBlockerActive: enabled);
    notifyListeners();
  }

  // Stops the soundscape when leaving the Focus tab
  Future<void> stopSoundscape() async {
    await _soundscapeService.stopSound();
  }

  
  // Starts a new focus session
  Future<void> startFocusSession() async {
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

    // Create an ID and save the start time
    final now = DateTime.now();

    _currentSessionId = now.millisecondsSinceEpoch.toString();
    _sessionStartTimestamp = now;

    final totalSeconds = duration * 60;

    // Create the session model
    _currentSession = FocusSessionModel(
      id: _currentSessionId!,
      userId: currentUser.uid,
      startTime: now,
      duration: totalSeconds,
      sessionType: SessionType.focus,
      sessionStatus: SessionStatus.active,
      xpEarned: 0,
      focusGoal: _state.focusGoal,
      elapsedSeconds: 0,
      remainingSeconds: totalSeconds,
      lastUpdatedAt: now,
    );

    // Reset persistence counter
    _lastPersistedElapsedSeconds = 0;

    // Save the active session locally
    await _repository.saveSessionLocally(_currentSession!);

    // Update the UI state
    _state = _state.copyWith(
      isTimerRunning: true,
      isTimerPaused: false,
      isRecoveryPending: false,
      remainingSeconds: totalSeconds,
      elapsedSeconds: 0,
      errorMessage: null,
    );

    notifyListeners();

    _runTimerLoop();
  }


  // Updates the timer every second
  void _runTimerLoop() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        // Do not update the timer while it is paused
        if (_state.isTimerPaused) return;

        if (_state.remainingSeconds > 0) {
          final newRemaining = _state.remainingSeconds - 1;
          final newElapsed = _state.elapsedSeconds + 1;

          _state = _state.copyWith(
            remainingSeconds: newRemaining,
            elapsedSeconds: newElapsed,
          );

          notifyListeners();

          // Persist progress every 5 seconds
          if (newElapsed - _lastPersistedElapsedSeconds >= 5) {
            _lastPersistedElapsedSeconds = newElapsed;
            unawaited(_persistSessionProgress());
          }

          // Finish the session when the timer reaches zero
          if (newRemaining == 0) {
            unawaited(_completeFocusSession());
          }
        }
      },
    );
  }

// Saves the current session progress locally
Future<void> _persistSessionProgress() async {
  final session = _currentSession;

  if (session == null) return;

  final now = DateTime.now();

  final updatedSession = session.copyWith(
    elapsedSeconds: _state.elapsedSeconds,
    remainingSeconds: _state.remainingSeconds,
    lastUpdatedAt: now,
    sessionStatus: _state.isTimerPaused
        ? SessionStatus.paused
        : SessionStatus.active,
  );

  _currentSession = updatedSession;

  await _repository.saveSessionLocally(updatedSession);
}



// Restores a session saved locally
Future<void> restoreActiveSession() async {
  if (_state.isTimerRunning || _state.isRecoveryPending) return;
  final user = _auth.currentUser;

  if (user == null) return;

  // Find an active or paused session
  final session = await _repository.getRecoverableSession(user.uid);

  if (session == null) return;

  final now = DateTime.now();

  int elapsed = session.elapsedSeconds;

  // Count the time passed outside the app only if the session was active
  if (session.sessionStatus == SessionStatus.active) {
    final lastUpdate = session.lastUpdatedAt ?? session.startTime;

    final secondsAway = now.difference(lastUpdate).inSeconds;

    if (secondsAway > 0) {
      elapsed += secondsAway;
    }
  }

  // Do not exceed the original session duration
  if (elapsed > session.duration) {
    elapsed = session.duration;
  }

  final remaining = session.duration - elapsed;

  // If the session expired, complete it automatically
  if (remaining <= 0) {
    final completedSession = session.copyWith(
      sessionStatus: SessionStatus.completed,
      elapsedSeconds: session.duration,
      remainingSeconds: 0,
      xpEarned: 5,
      lastUpdatedAt: now,
      clearPausedAt: true,
      isSynced: false,
    );

    await _repository.saveSessionLocally(completedSession);

   unawaited(_syncPendingSessions());

    return;
  }

    // Update the recovered session
    final recoveredSession = session.copyWith(
      elapsedSeconds: elapsed,
      remainingSeconds: remaining,
      lastUpdatedAt: now,
    );

    await _repository.saveSessionLocally(recoveredSession);

    // Keep the session available for the recovery screen
    _recoverySession = recoveredSession;

    _state = _state.copyWith(
      isRecoveryPending: true,
      elapsedSeconds: elapsed,
      remainingSeconds: remaining,
    );

    notifyListeners();
  }



  // Continues a recovered focus session
Future<void> continueRecoveredSession() async {
  final session = _recoverySession;

  if (session == null) return;

  final now = DateTime.now();

  // Calculate paused time if the session was paused
  int additionalPausedSeconds = 0;

  if (session.sessionStatus == SessionStatus.paused &&
      session.pausedAt != null) {
    additionalPausedSeconds =
        now.difference(session.pausedAt!).inSeconds;
  }

  // Restore the session as the current session
  _currentSession = session.copyWith(
    sessionStatus: SessionStatus.active,
    totalPausedSeconds:
        session.totalPausedSeconds + additionalPausedSeconds,
    clearPausedAt: true,
    lastUpdatedAt: now,
  );

  _currentSessionId = session.id;
  _sessionStartTimestamp = session.startTime;
  _lastPersistedElapsedSeconds = session.elapsedSeconds;

  await _repository.saveSessionLocally(_currentSession!);

  // Clear recovery information
  _recoverySession = null;

  // Restart the timer with the recovered progress
  _state = _state.copyWith(
    isRecoveryPending: false,
    isTimerRunning: true,
    isTimerPaused: false,
    elapsedSeconds: session.elapsedSeconds,
    remainingSeconds: session.remainingSeconds,
    errorMessage: null,
  );

  notifyListeners();

  _runTimerLoop();

  await _soundscapeService.resumeSound();
}

  // Pauses the current session and its sound

Future<void> pauseSession() async {
  if (!_state.isTimerRunning || _state.isTimerPaused) return;

  final now = DateTime.now();

  // Update the UI state
  _state = _state.copyWith(isTimerPaused: true);
  notifyListeners();

  // Update the current session
  if (_currentSession != null) {
    _currentSession = _currentSession!.copyWith(
      sessionStatus: SessionStatus.paused,
      elapsedSeconds: _state.elapsedSeconds,
      remainingSeconds: _state.remainingSeconds,
      pausedAt: now,
      lastUpdatedAt: now,
    );

    // Save the paused session locally
    await _repository.saveSessionLocally(_currentSession!);
  }

  await _soundscapeService.pauseSound();
}
  // Resumes the current session and its sound
 // Resumes the current session and its sound
Future<void> resumeSession() async {
  if (!_state.isTimerRunning || !_state.isTimerPaused) return;

  final now = DateTime.now();

  if (_currentSession != null) {
    // Calculate how long the session was paused
    final pausedDuration = _currentSession!.pausedAt != null
        ? now.difference(_currentSession!.pausedAt!).inSeconds
        : 0;

    _currentSession = _currentSession!.copyWith(
      sessionStatus: SessionStatus.active,
      totalPausedSeconds:
          _currentSession!.totalPausedSeconds + pausedDuration,
      clearPausedAt: true,
      lastUpdatedAt: now,
    );

    // Save the resumed session locally
    await _repository.saveSessionLocally(_currentSession!);
  }

  _state = _state.copyWith(isTimerPaused: false);
  notifyListeners();

  await _soundscapeService.resumeSound();
}



  // Restarts a recovered session as a new session
Future<void> restartRecoveredSession() async {
  if (_recoverySession == null) return;

  // Use the recovered session as the current session
  _currentSession = _recoverySession;

  _state = _state.copyWith(
    elapsedSeconds: _recoverySession!.elapsedSeconds,
    remainingSeconds: _recoverySession!.remainingSeconds,
  );

  // Mark the previous session as abandoned
  await _saveSessionToStorage(SessionStatus.abandoned);

  // Clear the recovery information
  _recoverySession = null;

  _resetTimerState();

  // Start a completely new session
  await startFocusSession();
}


  // Finishes a recovered session without completing the timer
Future<void> finishRecoveredSession() async {
  final session = _recoverySession;

  if (session == null) return;

  // Restore the recovered session as the current session
  _currentSession = session;

  _state = _state.copyWith(
    elapsedSeconds: session.elapsedSeconds,
    remainingSeconds: session.remainingSeconds,
  );

  // Mark the session as abandoned (2 XP)
  await _saveSessionToStorage(SessionStatus.abandoned);

  _recoverySession = null;

  _resetTimerState();
}


  // Cancels the current session
  Future<void> cancelSession() async {
    if (!_state.isTimerRunning) return;

    await _saveSessionToStorage(SessionStatus.abandoned);
    await stopSoundscape();
    _resetTimerState();
  }

 
// Completes the session when the timer reaches zero
Future<void> _completeFocusSession() async {
  await _saveSessionToStorage(SessionStatus.completed);

  // Keep the completed session information for the celebration dialog
  _completionSession = _currentSession;

  // Stop the timer
  _timer?.cancel();
  _timer = null;

  // Show the completion dialog immediately
  _state = _state.copyWith(
    isTimerRunning: false,
    isTimerPaused: false,
    isCompletionPending: true,
    remainingSeconds: 0,
  );

  notifyListeners();

  // Stop the soundscape independently
  await stopSoundscape();
}

  // Closes the completion dialog and returns to the Focus setup screen
  void dismissCompletionDialog() {
    if (!_state.isCompletionPending) return;

    _resetTimerState();
  }


// Saves the session locally and starts cloud synchronization
Future<void> _saveSessionToStorage(SessionStatus status) async {
  final session = _currentSession;

  if (session == null) {
    _state = _state.copyWith(
      errorMessage: 'Error al registrar la sesión',
    );
    notifyListeners();
    return;
  }

  // 5 XP if completed, 2 XP if abandoned
  final int earnedXp =
      (status == SessionStatus.completed) ? 5 : 2;

  final finalSession = session.copyWith(
    sessionStatus: status,
    xpEarned: earnedXp,
    elapsedSeconds: _state.elapsedSeconds,
    remainingSeconds: _state.remainingSeconds,
    lastUpdatedAt: DateTime.now(),
    clearPausedAt: true,
    isSynced: false,
  );

  _currentSession = finalSession;

  try {
    // Save locally first, without depending on internet
    await _repository.saveSessionLocally(finalSession);

    // Start cloud synchronization in the background
    unawaited(_syncPendingSessions());
  } catch (e) {
    _state = _state.copyWith(
      errorMessage: 'No se pudo guardar la sesión localmente',
    );
    notifyListeners();
  }
}

// Synchronizes pending sessions with Firestore
Future<void> _syncPendingSessions() async {
  _state = _state.copyWith(isSyncing: true);
  notifyListeners();

  try {
    await _repository.syncUnsyncedSessions();
  } catch (e) {
    debugPrint('Could not sync sessions: $e');
  } finally {
    _state = _state.copyWith(isSyncing: false);
    notifyListeners();
  }
}

  // Resets the timer and current session information
  void _resetTimerState() {
    _timer?.cancel();
    _timer = null;

    _currentSessionId = null;
    _sessionStartTimestamp = null;
    _currentSession = null;
    _lastPersistedElapsedSeconds = 0;
    _recoverySession = null;
    _completionSession = null;

    _state = _state.copyWith(
      isTimerRunning: false,
      isTimerPaused: false,
      remainingSeconds: 0,
      elapsedSeconds: 0,
      isRecoveryPending: false,
      isCompletionPending: false,
    );

    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel the timer and connectivity listener when the ViewModel is removed
    _connectivitySubscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}

import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/focus_session_model.dart';
import 'focus_remote_datasource.dart';

/// Repository that manages local focus sessions and synchronization with Firestore
class FocusSessionRepository {
  static final _changes = StreamController<void>.broadcast();
  Stream<void> watchChanges() => _changes.stream;

  final FocusRemoteDatasource _remoteDatasource;

  static const String _storageKey = 'local_focus_sessions';

  FocusSessionRepository({FocusRemoteDatasource? remoteDatasource})
      : _remoteDatasource =
            remoteDatasource ?? FocusRemoteDatasource();

  /// Gets the focus sessions stored locally.
  Future<List<FocusSessionModel>> getLocalSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);

    return jsonList
        .map((map) => FocusSessionModel.fromMap(map))
        .toList();
  }

  /// Saves the current list of sessions in local storage.
  Future<void> _saveLocalSessions(
      List<FocusSessionModel> sessions) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = sessions.map((s) => s.toMap()).toList();

    await prefs.setString(_storageKey, jsonEncode(jsonList));

    _changes.add(null);
  }

  /// Saves a new session or updates it if it already exists.
  Future<void> saveSessionLocally(
      FocusSessionModel session) async {
    final currentSessions = await getLocalSessions();

    final index = currentSessions.indexWhere(
      (s) => s.id == session.id,
    );

    if (index != -1) {
      currentSessions[index] = session;
    } else {
      currentSessions.add(session);
    }

    await _saveLocalSessions(currentSessions);
  }

  /// Updates an existing session using its ID.
  Future<void> updateSession(
      FocusSessionModel updatedSession) async {
    final sessions = await getLocalSessions();

    final index = sessions.indexWhere(
      (s) => s.id == updatedSession.id,
    );

    if (index == -1) return;

    sessions[index] = updatedSession;

    await _saveLocalSessions(sessions);
  }

  /// Gets the latest active or paused session for a user.
  Future<FocusSessionModel?> getRecoverableSession(
      String userId) async {
    final sessions = await getLocalSessions();

    final recoverableSessions = sessions.where((session) {
      return session.userId == userId &&
          (session.sessionStatus == SessionStatus.active ||
              session.sessionStatus == SessionStatus.paused);
    }).toList();

    if (recoverableSessions.isEmpty) return null;

    recoverableSessions.sort(
      (a, b) => b.startTime.compareTo(a.startTime),
    );

    return recoverableSessions.first;
  }

  /// Gets only completed or abandoned sessions that need synchronization.
  Future<List<FocusSessionModel>> getUnsyncedSessions() async {
    final sessions = await getLocalSessions();

    return sessions.where((session) {
      final isFinished =
          session.sessionStatus == SessionStatus.completed ||
          session.sessionStatus == SessionStatus.abandoned;

      return !session.isSynced && isFinished;
    }).toList();
  }

  /// Tries to upload finished unsynchronized sessions to Firestore.
  Future<void> syncUnsyncedSessions() async {
    final allSessions = await getLocalSessions();

    final updatedList = <FocusSessionModel>[];

    for (var session in allSessions) {
      final isFinished =
          session.sessionStatus == SessionStatus.completed ||
          session.sessionStatus == SessionStatus.abandoned;

      if (!session.isSynced && isFinished) {
        try {
          await _remoteDatasource.saveSession(session);

          updatedList.add(
            session.copyWith(isSynced: true),
          );
        } catch (e) {
          updatedList.add(session);
        }
      } else {
        updatedList.add(session);
      }
    }

    await _saveLocalSessions(updatedList);
  }
}

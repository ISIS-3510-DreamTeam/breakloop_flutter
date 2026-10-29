import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/focus_session_model.dart';
import 'focus_remote_datasource.dart';

/// Repository that manages local focus sessions and synchronization with Firestore
class FocusSessionRepository {
  final FocusRemoteDatasource _remoteDatasource;

  // key used to store focus sessions locally
  static const String _storageKey = 'local_focus_sessions';

  // Uses the provided remote datasource or creates a default one
  FocusSessionRepository({FocusRemoteDatasource? remoteDatasource})
      : _remoteDatasource =
            remoteDatasource ?? FocusRemoteDatasource();

  /// Gets the focus sessions stored locally.
  Future<List<FocusSessionModel>> getLocalSessions() async {
    // Get access to local storage.
    final prefs = await SharedPreferences.getInstance();

    // Get the stored sessions as a JSON string.
    final jsonString = prefs.getString(_storageKey);

    // If there are no stored sessions, return an empty list
    if (jsonString == null) return [];

    // Convert the JSON string into a list.
    final List<dynamic> jsonList = jsonDecode(jsonString);

    // Convert each item into a FocusSessionModel
    return jsonList
        .map((map) => FocusSessionModel.fromMap(map))
        .toList();
  }

  // Saves the current list of sessions in local storage
  Future<void> _saveLocalSessions(
      List<FocusSessionModel> sessions) async {
    // Get access to local storage.
    final prefs = await SharedPreferences.getInstance();

    // Convert the sessions into maps.
    final jsonList = sessions.map((s) => s.toMap()).toList();

    // Convert the list into JSON and save it.
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Saves a new focus session locally
  Future<void> saveSessionLocally(
      FocusSessionModel session) async {
    // Get the sessions already stored.
    final currentSessions = await getLocalSessions();

    // Add the new session to the list
    currentSessions.add(session);

    // Save the updated list.
    await _saveLocalSessions(currentSessions);
  }

  // Gets only the sessions that have not been synchronized
  Future<List<FocusSessionModel>> getUnsyncedSessions() async {
    final sessions = await getLocalSessions();

    // Keep only sessions that still need to be uploaded
    return sessions.where((s) => !s.isSynced).toList();
  }

  // Tries to upload all unsynchronized sessions to Firestore
  Future<void> syncUnsyncedSessions() async {
    // Get all locally stored sessions.
    final allSessions = await getLocalSessions();

    // List that will contain the updated sessions
    final updatedList = <FocusSessionModel>[];

    // Check each session
    for (var session in allSessions) {
      if (!session.isSynced) {
        try {
          // Try to upload the session to Firestore
          await _remoteDatasource.saveSession(session);

          // Mark the session as synchronized
          updatedList.add(session.copyWith(isSynced: true));
        } catch (e) {
          // If the upload fails, keep it unsynchronized
          updatedList.add(session);
        }
      } else {
        // Keep already synchronized sessions unchanged
        updatedList.add(session);
      }
    }

    // Save the updated synchronization status locally
    await _saveLocalSessions(updatedList);
  }
}
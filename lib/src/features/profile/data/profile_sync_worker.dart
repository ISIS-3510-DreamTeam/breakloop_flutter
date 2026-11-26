import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'package:breakloop_flutter/firebase_options.dart';

import 'profile_repository.dart';

/// Sends the name and photo changed offline when the connection comes back.
class ProfileSyncWorker {
  static const String uniqueName = 'profile-sync';
  static const String taskName = 'profile-sync';
  static const String _uidKey = 'uid';
  static const String _uiPortName = 'breakloop.profile.ui_port';

  static ReceivePort? _uiPort;

  // ---- UI side ----

  // Enqueue work: runs when there is internet available, replaces a pending one
  // and on fail retries with linear backoff of 10 s
  static Future<void> schedule(String uid) {
    return Workmanager().registerOneOffTask(
      uniqueName,
      taskName,
      inputData: {_uidKey: uid},
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
  }

  // Lets the profile screen know when the worker finished
  static void listenForUiRefresh(VoidCallback onRefresh) {
    IsolateNameServer.removePortNameMapping(_uiPortName);
    _uiPort?.close();

    final port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, _uiPortName);
    port.listen((_) => onRefresh());
    _uiPort = port;
  }

  static void stopListeningForUiRefresh() {
    final port = _uiPort;
    if (port == null) return;
    IsolateNameServer.removePortNameMapping(_uiPortName);
    port.close();
    _uiPort = null;
  }

  // ---- Worker side ----

  /// true = success. false = retry
  static Future<bool> run(Map<String, dynamic>? inputData) async {
    final uid = inputData?[_uidKey] as String?;
    if (uid == null) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      }
      // Wait for the saved session, Firestore and Storage rules need the user
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user?.uid != uid) return true;

      await ProfileRepository().syncPendingChanges(uid);
      return true;
    } catch (e) {
      debugPrint('[ProfileSyncWorker] sync failed, will retry: $e');
      return false;
    } finally {
      IsolateNameServer.lookupPortByName(_uiPortName)?.send('changed');
    }
  }
}

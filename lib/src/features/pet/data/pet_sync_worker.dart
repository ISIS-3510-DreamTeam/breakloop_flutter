
import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

// Ajusta al archivo generado por FlutterFire (firebase_options.dart).
import 'package:breakloop_flutter/firebase_options.dart';

import 'pet_repository.dart';

class PetSyncWorker {
  static const String uniqueName = 'pet-sync';
  static const String taskName = 'pet-sync';
  static const String _uiPortName = 'breakloop.pet.ui_port';

  static ReceivePort? _uiPort;

  // ---- UI side ----

  //Enqueue work: runs when there is internet available, substitutes a pending one and
  //on fail retries with lineal backoff of 10 s
  static Future<void> schedule() {
    return Workmanager().registerOneOffTask(
      uniqueName,
      taskName,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
  }


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

  // ---- Worker side  ----

  /// true = success. false = retry
  static Future<bool> run() async {
    PetRepository? repository;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
      repository = PetRepository();
      await repository.syncWithServer();
      return true;
    } catch (e) {
      debugPrint('[PetSyncWorker] sync failed, will retry: $e');
      return false;
    } finally {
      repository?.dispose();

      IsolateNameServer.lookupPortByName(_uiPortName)?.send('changed');
    }
  }
}
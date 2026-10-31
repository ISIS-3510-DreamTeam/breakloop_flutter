
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

  // ---- Lado UI ----

  /// Encola el trabajo: corre cuando hay internet, reemplaza uno pendiente,
  /// y si falla reintenta con backoff lineal de 10 s.
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

  /// Registra un puerto para que el worker (otro isolate) avise a la UI.
  static void listenForUiRefresh(VoidCallback onRefresh) {
    stopListeningForUiRefresh();
    final port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, _uiPortName);
    port.listen((_) => onRefresh());
    _uiPort = port;
  }

  static void stopListeningForUiRefresh() {
    IsolateNameServer.removePortNameMapping(_uiPortName);
    _uiPort?.close();
    _uiPort = null;
  }

  // ---- Lado worker (corre en otro isolate; no hay Provider, ni Firebase listo) ----

  /// true = éxito. false = reintentar (equivale a Result.retry()).
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
      // Aunque falle a mitad (p. ej. ya descargó la mascota), la UI se actualiza.
      IsolateNameServer.lookupPortByName(_uiPortName)?.send('changed');
    }
  }
}
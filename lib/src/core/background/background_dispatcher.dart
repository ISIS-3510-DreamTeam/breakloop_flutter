
import 'dart:ui';

import 'package:workmanager/workmanager.dart';

import '../../features/pet/data/pet_sync_worker.dart';

/// Un único dispatcher para toda la app: despacha por nombre de tarea.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    switch (task) {
      case PetSyncWorker.taskName:
        return PetSyncWorker.run();
      default:
        return true;
    }
  });
}
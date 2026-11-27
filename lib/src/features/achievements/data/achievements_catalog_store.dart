import 'dart:io';

import 'package:path_provider/path_provider.dart';

// Keeps the last catalog received from the backend, in a file, for when there is no network.
class AchievementsCatalogStore {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/achievements_catalog.json');
  }

  // Writes a temporary file first, so a crash never leaves a half-written catalog.
  Future<void> save(String json) async {
    final file = await _file();
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(json, flush: true);
    await temp.rename(file.path);
  }

  Future<String?> read() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  }
}
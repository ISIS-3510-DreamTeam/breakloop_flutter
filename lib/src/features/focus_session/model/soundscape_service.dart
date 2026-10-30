import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:breakloop_flutter/src/features/focus_session/data/soundscape_cache.dart';
import '../viewmodel/focus_session_ui_state.dart';

class SoundscapeService {
  final SoundscapeCache _cache = SoundscapeCache();

  Future<File?> getSoundFile(Soundscape soundscape) async {
    if (soundscape == Soundscape.silence) return null;
    String soundName = soundscape.name.toLowerCase();

    try {
      final file = await compute(_loadSoundInBackground, {'cache': _cache, 'name': soundName});
      return file;
    } catch (e) {
      debugPrint('Error al obtener el soundscape: $e');
      return null;
    }
  }
  static Future<File> _loadSoundInBackground(Map<String, dynamic> params) async {
    final cache = params['cache'] as SoundscapeCache;
    String name = params['name'] as String;
    return await cache.getSound(name);
  }
}
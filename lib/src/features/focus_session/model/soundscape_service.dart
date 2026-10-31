
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/soundscape_cache.dart';
import '../viewmodel/focus_session_ui_state.dart';

class SoundscapeService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SoundscapeCache _cache = SoundscapeCache();

Future<void> playSoundscape(Soundscape soundscape) async {
  if (soundscape == Soundscape.silence) {
    await stopSound();
    return;
  }

  final soundName = switch (soundscape) {
    Soundscape.rain => 'rain',
    Soundscape.fire => 'hearth',
    Soundscape.silence => '',
  };

  try {
    final file = await _cache.getSound(soundName);

    if (!await file.exists() || await file.length() == 0) {
      throw Exception('Soundscape file not found or empty');
    }

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(DeviceFileSource(file.path));

    debugPrint('Playing soundscape: $soundName');
  } catch (e) {
    debugPrint('Error playing soundscape: $e');
  }
}

    Future<void> pauseSound() async {
      await _audioPlayer.pause();
    }

    Future<void> resumeSound() async {
      await _audioPlayer.resume();
    }

    Future<void> stopSound() async {
      await _audioPlayer.stop();
    }

    Future<void> dispose() async {
      await _audioPlayer.dispose();
    }
}

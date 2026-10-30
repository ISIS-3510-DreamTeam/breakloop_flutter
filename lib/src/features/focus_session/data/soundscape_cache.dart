
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class SoundscapeCache {
  static const String _baseUrl =
      'https://breakloop-backend-14746672383.southamerica-west1.run.app/api/soundscapes';

  Future<File> getSound(String name) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('El nombre del sonido no puede estar vacío');
    }

    // Get the application directory on the main isolate
    final appDir = await getApplicationDocumentsDirectory();

    final directoryPath = '${appDir.path}/soundscapes';

    // Download or retrieve the sound in a background isolate
    final filePath = await compute(
      _getSoundInBackground,
      {
        'name': name,
        'directoryPath': directoryPath,
      },
    );

    return File(filePath);
  }
}

// Top-level function executed in a background isolate
Future<String> _getSoundInBackground(
    Map<String, String> parameters) async {
  final name = parameters['name']!;
  final directoryPath = parameters['directoryPath']!;

  final carpeta = Directory(directoryPath);

  if (!await carpeta.exists()) {
    await carpeta.create(recursive: true);
  }

  final archivo = File('${carpeta.path}/$name.mp3');

  // Check if the sound is already cached
  if (await archivo.exists() && await archivo.length() > 0) {
    return archivo.path;
  }

  final temporal = File('${carpeta.path}/$name.tmp');
  final url = Uri.parse('${SoundscapeCache._baseUrl}/$name');

  try {
    // Download the audio file
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw HttpException(
        'Error downloading soundscape: ${response.statusCode}',
      );
    }

    await temporal.writeAsBytes(response.bodyBytes);

    if (await temporal.length() == 0) {
      throw StateError('The downloaded audio is empty');
    }

    // Replace the temporary file with the final cached file
    if (await archivo.exists()) {
      await archivo.delete();
    }

    await temporal.rename(archivo.path);

    return archivo.path;
  } catch (e) {
    if (await temporal.exists()) {
      await temporal.delete();
    }

    rethrow;
  }
}

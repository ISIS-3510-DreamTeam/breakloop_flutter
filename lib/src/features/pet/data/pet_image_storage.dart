import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../model/pet_mood.dart';

class PetImageStorage {
  // getApplicationSupportDirectory = Context.filesDir in Android.
  Future<Directory> get _folder async =>
      Directory('${(await getApplicationSupportDirectory()).path}/pet'); // current pet actual
  Future<Directory> get _tempFolder async =>
      Directory('${(await getApplicationSupportDirectory()).path}/pet_download'); // the one being downloaded

  /// Theres a file per mood
  Future<Uint8List?> readImageBytes(PetMood mood) async {
    try {
      final file = File('${(await _folder).path}/${mood.apiName}');
      return await file.exists() ? await file.readAsBytes() : null;
    } on FileSystemException {
      return null; //the folder may have been replaced while we where reading.
    }
  }

  Future<void> startDownload() async {
    final temp = await _tempFolder;
    if (await temp.exists()) await temp.delete(recursive: true);
    await temp.create(recursive: true);
  }

  Future<void> saveDownloadedImage(String moodName, Uint8List bytes) async {
    final temp = await _tempFolder;
    await File('${temp.path}/$moodName').writeAsBytes(bytes, flush: true);
  }

  Future<void> finishDownload() async {
    final folder = await _folder;
    final temp = await _tempFolder;
    if (await folder.exists()) await folder.delete(recursive: true); // previous images
    try {
      await temp.rename(folder.path);
    } on FileSystemException catch (e) {
      throw FileSystemException('Could not save pet images', folder.path, e.osError);
    }
  }
}
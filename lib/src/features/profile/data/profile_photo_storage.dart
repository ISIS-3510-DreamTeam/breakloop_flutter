import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Keeps the compressed profile photo as a file on the device.
/// It is shown without connection and it is the file the upload reads.
class ProfilePhotoStorage {
  // getApplicationSupportDirectory = Context.filesDir in Android
  Future<File> _file(String uid) async => File(
      '${(await getApplicationSupportDirectory()).path}/profile/$uid.jpg');

  // Gets the saved photo, or null if the user never picked one on this device
  Future<Uint8List?> readPhoto(String uid) async {
    final file = await _file(uid);
    return await file.exists() ? await file.readAsBytes() : null;
  }

  // Saves the photo, replacing the previous one
  Future<void> savePhoto(String uid, Uint8List photo) async {
    final file = await _file(uid);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(photo, flush: true);
  }

  // Removes the saved photo, if there is one
  Future<void> deletePhoto(String uid) async {
    final file = await _file(uid);
    if (await file.exists()) await file.delete();
  }
}

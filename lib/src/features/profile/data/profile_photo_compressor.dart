import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Makes the profile photo small before saving and uploading it.
class ProfilePhotoCompressor {
  // Size of the square photo, enough for the avatar in any screen
  static const int _size = 512;
  static const int _jpgQuality = 80;

  // Decoding and resizing a camera photo takes hundreds of ms,
  // so it runs in a separate Isolate to keep the UI smooth
  Future<Uint8List> compress(Uint8List bytes) =>
      Isolate.run(() => _compress(bytes));

  // Runs inside the Isolate, so it must be static
  static Uint8List _compress(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) throw const FormatException('Unsupported image');

    // Camera photos store the rotation in EXIF, apply it before cropping
    final rotated = img.bakeOrientation(image);
    final square = img.copyResizeCropSquare(rotated, size: _size);
    return img.encodeJpg(square, quality: _jpgQuality);
  }
}

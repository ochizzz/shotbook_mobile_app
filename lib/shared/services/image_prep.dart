import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Re-encodes a picked photo before upload: applies the camera rotation,
/// scales it down to [maxSide] and drops all metadata (EXIF, GPS location,
/// device info). Runs off the UI thread. Returns JPEG bytes.
Future<Uint8List> prepareImageForUpload(
  Uint8List bytes, {
  int maxSide = 2048,
}) => compute(_prepare, (bytes, maxSide));

Uint8List _prepare((Uint8List, int) input) {
  final (bytes, maxSide) = input;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException(
      'Could not open that image. Please choose another file.',
    );
  }
  var image = img.bakeOrientation(decoded);
  final longest = image.width > image.height ? image.width : image.height;
  if (longest > maxSide) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxSide)
        : img.copyResize(image, height: maxSide);
  }
  image.exif = img.ExifData();
  return img.encodeJpg(image, quality: 85);
}

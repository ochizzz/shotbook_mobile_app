import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shotbook/shared/services/image_prep.dart';

void main() {
  test('uploads are scaled down and carry no EXIF or GPS data', () async {
    final source = img.Image(width: 3000, height: 1500);
    source.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(55, 1);
    source.exif.imageIfd['Model'] = img.IfdValueAscii('Test Phone');
    final original = img.encodeJpg(source);
    expect(img.decodeJpgExif(original)?.gpsIfd.isEmpty, isFalse);

    final prepared = await prepareImageForUpload(original);
    final decoded = img.decodeJpg(prepared)!;

    expect(decoded.width, 2048);
    expect(decoded.height, 1024);
    final exif = img.decodeJpgExif(prepared);
    expect(
      exif == null || (exif.gpsIfd.isEmpty && exif.imageIfd.isEmpty),
      isTrue,
    );
  });
}

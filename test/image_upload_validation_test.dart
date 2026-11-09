import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/feed/data/image_upload_validation.dart';

void main() {
  test(
    'accepts supported image types and enforces the 10 MiB upload limit',
    () {
      expect(
        ImageUploadValidation.validate('photo.jpg', [0xff, 0xd8, 0xff]),
        'image/jpeg',
      );
      expect(
        ImageUploadValidation.validate('photo.PNG', [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ]),
        'image/png',
      );
      expect(
        ImageUploadValidation.validate('photo.webp', [
          82,
          73,
          70,
          70,
          0,
          0,
          0,
          0,
          87,
          69,
          66,
          80,
        ]),
        'image/webp',
      );
      expect(
        () => ImageUploadValidation.validate('photo.gif', [1, 2, 3]),
        throwsFormatException,
      );
      expect(
        () => ImageUploadValidation.validate(
          'photo.jpg',
          List.filled(10 * 1024 * 1024 + 1, 0),
        ),
        throwsFormatException,
      );
      expect(
        () => ImageUploadValidation.validate('photo.jpg', [1, 2, 3]),
        throwsFormatException,
      );
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/camera/domain/camera_device.dart';
import 'package:shotbook/features/discover/data/photo_catalog_repository.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';

void main() {
  test('catalog has 100 photos across all eight categories', () {
    expect(seedPhotoReferences.length, 100);
    expect(seedPhotoReferences.map((photo) => photo.id).toSet().length, 100);
    for (final category in photoCategories.skip(1)) {
      expect(
        seedPhotoReferences.where((photo) => photo.category == category).length,
        greaterThanOrEqualTo(12),
        reason: category,
      );
    }
  });

  test('every photo has a phone recipe, a thumbnail, credit and English', () {
    final deviceIds = cameraDevices.map((device) => device.id).toSet();
    for (final photo in seedPhotoReferences) {
      expect(deviceIds, contains(photo.deviceId), reason: photo.id);
      expect(photo.thumbUrl, isNotEmpty, reason: photo.id);
      expect(photo.credit, isNotEmpty, reason: photo.id);
      expect(photo.license, isNot(contains('ND')), reason: photo.id);
      expect(photo.cameraSettings, isNotEmpty, reason: photo.id);
      final english = photo.localized('en');
      expect(english.title, isNot(photo.title), reason: photo.id);
      expect(english.deviceId, photo.deviceId);
    }
  });

  test('filters by category and case-insensitive query together', () {
    final results = filterPhotoReferences(
      seedPhotoReferences,
      category: 'Portrait',
      query: 'ВЕСНУШК',
    );

    expect(results.map((photo) => photo.id), ['portrait-01']);
  });

  test('unmatched query returns an empty list', () {
    expect(
      filterPhotoReferences(seedPhotoReferences, query: 'no such frame'),
      isEmpty,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/discover/data/photo_catalog_repository.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';

void main() {
  test(
    'seed catalog contains twenty references across all seven categories',
    () {
      expect(seedPhotoReferences.length, greaterThanOrEqualTo(20));
      expect(
        seedPhotoReferences.map((photo) => photo.category).toSet(),
        containsAll([
          'Portrait',
          'Street',
          'Full Body',
          'Lifestyle',
          'Couple',
          'Car',
          'Product',
        ]),
      );
    },
  );

  test('filters by category and case-insensitive query together', () {
    final results = filterPhotoReferences(
      seedPhotoReferences,
      category: 'Portrait',
      query: 'studio',
    );

    expect(results.map((photo) => photo.id), ['portrait-studio-light']);
  });

  test('unmatched query returns an empty list', () {
    expect(
      filterPhotoReferences(seedPhotoReferences, query: 'no such frame'),
      isEmpty,
    );
  });
}

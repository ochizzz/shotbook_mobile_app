import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/discover/domain/photo_reference.dart';

void main() {
  test('unset optional metadata is omitted from detail sections', () {
    const photo = PhotoReference(
      id: 'minimal',
      title: 'Minimal frame',
      description: 'A frame with no recorded settings.',
      imageUrl: 'https://example.invalid/frame.jpg',
      category: 'Portrait',
      sourcePage: 'https://example.invalid',
      credit: 'Demo',
      license: 'Public domain',
    );

    expect(photo.poseData, isEmpty);
    expect(photo.cameraSettings, isEmpty);
    expect(photo.editingSettings, isEmpty);
  });

  test('camera settings include only populated values', () {
    const photo = PhotoReference(
      id: 'partial',
      title: 'Partial frame',
      description: 'Only the device is known.',
      imageUrl: 'https://example.invalid/frame.jpg',
      category: 'Portrait',
      sourcePage: 'https://example.invalid',
      credit: 'Demo',
      license: 'Public domain',
      device: 'Smartphone',
      iso: ' ',
    );

    expect(photo.cameraSettings, {'Device': 'Smartphone'});
  });

  test(
    'remote photo metadata round trips nullable camera and JSON details',
    () {
      final photo = PhotoReference.fromJson({
        'id': 'remote-1',
        'title': 'Rain after dark',
        'description': 'Reflections on the pavement.',
        'image_url': 'https://example.test/rain.webp',
        'category': 'Street',
        'source_type': 'community',
        'author_id': 'user-1',
        'pose_data': {'Gaze': 'Into the distance'},
        'editing_data': {'Preset': 'Night silver', 'Grain': '12'},
        'created_at': '2026-11-09T12:00:00Z',
      });

      expect(photo.authorId, 'user-1');
      expect(photo.sourceType, 'community');
      expect(photo.poseData, {'Gaze': 'Into the distance'});
      expect(photo.cameraSettings, isEmpty);
      expect(PhotoReference.fromJson(photo.toJson()).editingSettings, {
        'Preset': 'Night silver',
        'Grain': '12',
      });
    },
  );
}

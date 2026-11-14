import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';
import 'package:shotbook/features/pro_camera/camera_recipe.dart';

void main() {
  test('shutter speeds in Russian and English', () {
    expect(parseShutterNs('1/250 с'), 4000000);
    expect(parseShutterNs('1/60 s'), 16666667);
    expect(parseShutterNs('2 с'), 2000000000);
    expect(parseShutterNs('Авто'), isNull);
  });

  test('ISO, exposure compensation and white balance', () {
    expect(parseIso('100'), 100);
    expect(parseIso('ISO 800'), 800);
    expect(parseIso('Авто'), isNull);
    expect(parseEv('−0,3 EV'), closeTo(-0.3, 1e-9));
    expect(parseEv('+0.7 EV'), closeTo(0.7, 1e-9));
    expect(parseEv('0 EV'), 0);
    expect(parseKelvin('5000 K'), 5000);
    expect(parseKelvin('3300K'), 3300);
    expect(parseKelvin('Авто, теплее на +3'), isNull);
    expect(parseKelvin('Облачно'), 6500);
  });

  test('zoom from lens notes', () {
    expect(parseZoom('70 мм (3×)', 23), 3);
    expect(parseZoom('Ultra-wide 0.6x', 23), 0.6);
    expect(parseZoom('120 mm', 24), 5);
    expect(parseZoom('Основной объектив', 24), isNull);
  });

  test('every catalog recipe parses without errors', () {
    var withSettings = 0;
    for (final photo in seedPhotoReferences) {
      final recipe = CameraRecipe.fromPhoto(photo);
      if (!recipe.isEmpty) withSettings++;
      if (recipe.zoom != null) {
        expect(recipe.zoom, inInclusiveRange(0.5, 12), reason: photo.id);
      }
    }
    expect(withSettings, greaterThan(80));
  });
}

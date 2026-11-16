import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';
import 'package:shotbook/features/discover/domain/photo_reference.dart';
import 'package:shotbook/features/pro_camera/photo_look.dart';

PhotoReference _photo({
  String title = 'Frame',
  String? wb,
  Map<String, String> editing = const {},
}) => PhotoReference(
  id: 'x',
  title: title,
  description: '',
  imageUrl: '',
  category: 'Street',
  sourcePage: '',
  credit: '',
  license: '',
  whiteBalance: wb,
  editingData: editing,
);

void main() {
  test('black-and-white recipes produce a mono look', () {
    final look = lookFromPhoto(
      _photo(
        editing: {
          'Пресет': 'Ч/Б',
          'Контраст': '+25',
          'Тени': '−30',
          'Виньетка': '−15',
        },
      ),
    );
    expect(look.mono, isTrue);
    expect(look.contrast, closeTo(0.25, 1e-9));
    expect(look.shadows, closeTo(-0.3, 1e-9));
    expect(look.vignette, greaterThan(0));
    // Mono: every colour row reads the same luminance.
    final m = look.colorMatrix;
    expect(m[0], closeTo(m[5], 1e-9));
    expect(m[1], closeTo(m[6], 1e-9));
    expect(m[2], closeTo(m[12], 1e-9));
  });

  test('"Авто, теплее на +3" and warm film presets warm the look', () {
    expect(lookFromPhoto(_photo(wb: 'Авто, теплее на +3')).warmth, 0.12);
    final film = lookFromPhoto(_photo(editing: {'Пресет': 'Тёплая плёнка'}));
    expect(film.warmth, greaterThan(0));
    expect(film.fade, greaterThan(0));
    expect(film.grain, greaterThan(0));
    expect(lookFromPhoto(_photo(wb: 'Авто, холоднее')).warmth, lessThan(0));
  });

  test('English recipes work too', () {
    final look = lookFromPhoto(
      _photo(editing: {'Preset': 'B&W', 'Contrast': '+20', 'Shadows': '-10'}),
    );
    expect(look.mono, isTrue);
    expect(look.contrast, closeTo(0.2, 1e-9));
  });

  test('a recipe with no editing notes leaves the image untouched', () {
    final look = lookFromPhoto(_photo());
    expect(look.isNone, isTrue);
    expect(PhotoLook.none.colorMatrix, [
      1, 0, 0, 0, 0, //
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ]);
  });

  test('the catalog: B&W photos are detected and most recipes have a look', () {
    var mono = 0, withLook = 0;
    for (final photo in seedPhotoReferences) {
      final look = lookFromPhoto(photo);
      if (look.mono) mono++;
      if (!look.isNone) withLook++;
      for (final v in look.colorMatrix) {
        expect(v.isFinite, isTrue, reason: photo.id);
      }
    }
    expect(mono, greaterThanOrEqualTo(3));
    expect(withLook, greaterThan(seedPhotoReferences.length * 0.8));
  });
}

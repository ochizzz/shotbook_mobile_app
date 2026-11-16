import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/camera/domain/camera_device.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';
import 'package:shotbook/features/pro_camera/camera_recipe.dart';
import 'package:shotbook/features/recipe/adapt_photo.dart';
import 'package:shotbook/features/recipe/my_phone.dart';
import 'package:shotbook/features/recipe/phone_profile.dart';
import 'package:shotbook/features/recipe/recipe_engine.dart';

double _ev(double seconds, num iso, double aperture) =>
    math.log(seconds * iso / (aperture * aperture)) / math.ln2;

void main() {
  test('every phone in the guide has a lens profile', () {
    for (final device in cameraDevices) {
      expect(phoneLenses, contains(device.id), reason: device.id);
    }
  });

  test('a 70 mm portrait goes to the S23 Ultra 3× telephoto', () {
    const shot = OriginalShot(
      equivMm: 70,
      aperture: 2.8,
      seconds: 1 / 200,
      iso: 250,
    );
    final r = adaptShot(
      shot,
      phoneProfile('samsung-s23-ultra'),
      category: 'Couple',
    );
    expect(r.lens.kind, LensKind.tele);
    expect(r.zoom, 3.0);
    expect(r.seconds, closeTo(1 / 200, 1e-9));
    // f/2.4 lets in a bit more light than f/2.8: a lower ISO.
    expect(r.iso, 200);
    expect(r.notes, isNot(contains(RecipeNote.zoomShort)));
  });

  test('a long lens shot: periscope crop on the Ultra, advice elsewhere', () {
    const shot = OriginalShot(
      equivMm: 180,
      aperture: 7.1,
      seconds: 1 / 400,
      iso: 500,
    );
    final ultra = adaptShot(shot, phoneProfile('samsung-s23-ultra'));
    expect(ultra.lens.kind, LensKind.tele);
    expect(ultra.notes, isEmpty);
    final basic = adaptShot(shot, phoneProfile('nothing-phone-2'));
    expect(basic.lens.kind, LensKind.main);
    expect(basic.notes, contains(RecipeNote.zoomShort));
  });

  test('exposure matches the original unless a note says otherwise', () {
    for (final id in phoneLenses.keys) {
      final phone = phoneProfile(id);
      for (final photo in seedPhotoReferences) {
        final o = photo.original!;
        final r = adaptShot(o, phone, category: photo.category);
        final diff =
            _ev(r.seconds, r.iso, r.lens.aperture) -
            _ev(o.seconds, o.iso, o.aperture);
        if (!r.notes.contains(RecipeNote.nightMode) &&
            !r.notes.contains(RecipeNote.tooBright)) {
          expect(diff.abs(), lessThan(0.75), reason: '$id ${photo.id}');
        }
        expect(r.iso, inInclusiveRange(phone.isoMin, phone.isoMax));
      }
    }
  });

  test('moving people stay frozen', () {
    const shot = OriginalShot(
      equivMm: 35,
      aperture: 1.4,
      seconds: 1 / 2500,
      iso: 100,
    );
    final r = adaptShot(
      shot,
      phoneProfile('google-pixel-9'),
      category: 'Street',
    );
    expect(r.seconds, lessThanOrEqualTo(1 / 250));
  });

  test('much blurrier originals ask for Portrait mode', () {
    const shot = OriginalShot(
      equivMm: 85,
      aperture: 1.4,
      seconds: 1 / 250,
      iso: 100,
    );
    final r = adaptShot(
      shot,
      phoneProfile('apple-iphone-16'),
      category: 'Portrait',
    );
    expect(r.notes, contains(RecipeNote.portraitMode));
  });

  test('phone models are detected', () {
    expect(phoneIdForModel('samsung', 'SM-S918B'), 'samsung-s23-ultra');
    expect(phoneIdForModel('samsung', 'SM-S911B'), 'samsung-s23');
    expect(phoneIdForModel('samsung', 'SM-S928B'), 'samsung-s24-ultra');
    expect(phoneIdForModel('samsung', 'SM-S937B'), 'samsung-s25-edge');
    expect(phoneIdForModel('samsung', 'SM-A556B'), 'samsung-galaxy-a');
    expect(phoneIdForModel('Google', 'Pixel 8 Pro'), 'google-pixel-8');
    expect(phoneIdForModel('Google', 'Pixel 9a'), 'google-pixel-a');
    expect(phoneIdForModel('Xiaomi', '2304FPN6DG'), isNull);
  });

  test('adapted photos keep machine-readable settings for the camera', () {
    for (final photo in seedPhotoReferences) {
      final adapted = adaptToPhone(photo, 'samsung-s23-ultra', russian: true);
      expect(adapted.deviceId, 'samsung-s23-ultra');
      final recipe = CameraRecipe.fromPhoto(adapted, mainEquivalentMm: 23);
      expect(recipe.iso, isNotNull, reason: photo.id);
      expect(recipe.exposureNs, isNotNull, reason: photo.id);
      expect(recipe.zoom, isNotNull, reason: photo.id);
    }
  });
}

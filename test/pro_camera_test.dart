import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';
import 'package:shotbook/features/pro_camera/camera_recipe.dart';
import 'package:shotbook/features/pro_camera/pro_camera_controller.dart';
import 'package:shotbook/features/pro_camera/pro_camera_view.dart';

const _s23Ultra = ProCameraCapabilities(
  available: true,
  manualSensor: true,
  raw: true,
  isoMin: 50,
  isoMax: 3200,
  exposureMinNs: 100000,
  exposureMaxNs: 1000000000,
  evMin: -24,
  evMax: 24,
  evStep: 1 / 6,
  manualFocus: true,
  minFocusDiopters: 10,
  wbMode: 'cct',
  flash: true,
  zoomMin: 0.6,
  zoomMax: 10,
  mainEquivalentMm: 23,
);

void main() {
  test('a recipe sets manual exposure, EV, white balance and lens', () {
    const recipe = CameraRecipe(
      iso: 100,
      exposureNs: 4000000,
      ev: -0.3,
      kelvin: 5300,
      zoom: 3,
    );
    final s = const ProCameraSettings().withRecipe(recipe, _s23Ultra);
    expect(s.autoExposure, isFalse);
    expect(s.iso, 100);
    expect(s.exposureNs, 4000000);
    expect(s.ev, closeTo(-2 / 6, 1e-9));
    expect(s.autoWhiteBalance, isFalse);
    expect(s.kelvin, 5300);
    expect(s.zoom, 3);
  });

  test('without manual sensor control exposure stays automatic', () {
    const basic = ProCameraCapabilities(available: true, evMin: -2, evMax: 2);
    const recipe = CameraRecipe(iso: 100, exposureNs: 4000000, zoom: 3);
    final s = const ProCameraSettings().withRecipe(recipe, basic);
    expect(s.autoExposure, isTrue);
    expect(s.zoom, 1, reason: 'no zoom range reported');
  });

  test('reset returns every setting to automatic and 1x', () {
    final manual = const ProCameraSettings().copyWith(
      autoExposure: false,
      iso: 800,
      autoWhiteBalance: false,
      kelvin: 3300,
      autoFocus: false,
      zoom: 3,
      raw: true,
    );
    expect(manual.isDefault, isFalse);
    final reset = manual.reset();
    expect(reset.isDefault, isTrue);
    expect(reset.raw, isTrue, reason: 'the RAW choice is kept');
  });

  test('ISO and shutter dials offer every 1/3 stop', () {
    final iso = isoStops(50, 3200);
    expect(iso, containsAllInOrder([50, 64, 80, 100, 125, 160, 200]));
    expect(iso.last, 3200);
    final shutter = shutterStops(125000, 1000000000);
    expect(
      shutter.map(formatShutter),
      containsAllInOrder(['1/8000', '1/6400', '1/5000']),
    );
    expect(formatShutter(shutter.last), '1″');
  });

  test('shutter labels read like a camera', () {
    expect(formatShutter(4000000), '1/250');
    expect(formatShutter(500000000), '0.5″');
    expect(formatShutter(1000000000), '1″');
    expect(shutterStops(100000, 1000000000).first, 125000);
    expect(nearestStop(isoStops(50, 3200), 110), 100);
  });

  testWidgets('camera screen shows controls and disables RAW when absent', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('shotbook/pro_camera'),
      (call) async {
        calls.add(call.method);
        switch (call.method) {
          case 'capabilities':
            return {
              'available': true,
              'manualSensor': true,
              'raw': false,
              'isoMin': 50,
              'isoMax': 3200,
              'evMin': -12,
              'evMax': 12,
              'evStep': 1 / 6,
              'wbMode': 'gains',
              'zoomMin': 0.6,
              'zoomMax': 10.0,
            };
          case 'open':
            return {
              'textureId': 1,
              'previewWidth': 1440,
              'previewHeight': 1080,
              'raw': false,
            };
        }
        return null;
      },
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => call.method == 'requestPermissions' ? {1: 1} : 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProCameraView(
          photo: seedPhotoReferences.first,
          onOpened: () {},
          fallback: (_) => const Text('fallback'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('ISO'), findsOneWidget);
    expect(find.byKey(const Key('pro-apply-recipe')), findsOneWidget);
    final raw = tester.widget<GestureDetector>(
      find.byKey(const Key('pro-raw')),
    );
    expect(raw.onTap, isNull, reason: 'RAW unavailable on this phone');
    expect(calls, containsAll(['capabilities', 'open', 'setControls']));

    await tester.tap(find.byKey(const Key('pro-apply-recipe')));
    await tester.pump(const Duration(milliseconds: 60));
    expect(calls.where((c) => c == 'setControls').length, greaterThan(1));
    // The summary lists what was set, including the photo's filter.
    expect(find.textContaining('Applied:'), findsOneWidget);
    expect(find.textContaining('filter:'), findsOneWidget);
  });
}

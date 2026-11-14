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
  awbModes: [
    'auto',
    'incandescent',
    'fluorescent',
    'daylight',
    'cloudy',
    'shade',
  ],
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
      whiteBalance: 'daylight',
      zoom: 3,
    );
    final s = const ProCameraSettings().withRecipe(recipe, _s23Ultra);
    expect(s.autoExposure, isFalse);
    expect(s.iso, 100);
    expect(s.exposureNs, 4000000);
    expect(s.ev, closeTo(-2 / 6, 1e-9));
    expect(s.whiteBalance, 'daylight');
    expect(s.zoom, 3);
  });

  test('without manual sensor control exposure stays automatic', () {
    const basic = ProCameraCapabilities(
      available: true,
      evMin: -2,
      evMax: 2,
      awbModes: ['auto'],
    );
    const recipe = CameraRecipe(iso: 100, exposureNs: 4000000, zoom: 3);
    final s = const ProCameraSettings().withRecipe(recipe, basic);
    expect(s.autoExposure, isTrue);
    expect(s.zoom, 1, reason: 'no zoom range reported');
  });

  test('shutter labels read like a camera', () {
    expect(formatShutter(4000000), '1/250');
    expect(formatShutter(500000000), '0.5″');
    expect(formatShutter(1000000000), '1″');
    expect(shutterStops(100000, 1000000000).first, 125000);
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
              'awbModes': ['auto', 'daylight'],
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
    final raw = tester.widget<Switch>(find.byKey(const Key('pro-raw')));
    expect(raw.onChanged, isNull, reason: 'RAW unavailable on this phone');
    expect(calls, containsAll(['capabilities', 'open', 'setControls']));

    await tester.tap(find.byKey(const Key('pro-apply-recipe')));
    await tester.pump();
    expect(calls.where((c) => c == 'setControls').length, greaterThan(1));
  });
}

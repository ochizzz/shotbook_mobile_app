import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/app/router.dart';
import 'package:shotbook/features/discover/domain/photo_reference.dart';
import 'package:shotbook/features/share/domain/shooting_summary.dart';
import 'package:shotbook/features/share/presentation/share_card_screen.dart';
import 'package:shotbook/l10n/language_provider.dart';

PhotoReference _photo({
  String? iso,
  String? shutter,
  String? aperture,
  String? focal,
  String? device,
  String? camera,
  Map<String, String> editing = const {},
}) => PhotoReference(
  id: 'test',
  title: 'Test',
  description: '',
  imageUrl: '',
  category: 'Portrait',
  sourcePage: '',
  credit: '',
  license: '',
  iso: iso,
  shutterSpeed: shutter,
  aperture: aperture,
  focalLength: focal,
  device: device,
  camera: camera,
  editingData: editing,
);

Future<void> _openShareCard(WidgetTester tester) async {
  final router = createAppRouter();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [initialLanguageProvider.overrideWithValue('en')],
      child: ShotbookApp(router: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push('/photos/portrait-01/share');
  await tester.pumpAndSettle();
}

void main() {
  group('shooting summary', () {
    test('compacts catalog values into one line', () {
      final photo = _photo(
        iso: '100',
        shutter: '1/60 s',
        aperture: 'f/1.8 (fixed)',
        focal: '26 mm (1×)',
      );
      expect(shootingSummary(photo), 'ISO 100 · 1/60 · f1.8 · 26 mm');
      expect(shootingSummary(photo, focal: false), 'ISO 100 · 1/60 · f1.8');
    });

    test('skips values that are not numbers and missing ones', () {
      expect(
        shootingSummary(
          _photo(
            iso: 'Auto',
            shutter: 'Auto, no slower than 1/500 s',
            aperture: 'f/2.0 (fixed), f/2.8 in Portrait',
          ),
        ),
        'ISO Auto · f2.0',
      );
      expect(shootingSummary(_photo()), isNull);
    });

    test('device line and preset', () {
      final photo = _photo(
        device: 'Pixel 8 Pro',
        camera: 'main, 1x',
        editing: {'Preset': 'Warm film'},
      );
      expect(deviceSummary(photo), 'Pixel 8 Pro · main, 1x');
      expect(presetOf(photo), 'Warm film');
      expect(
        presetOf(_photo(editing: {'Пресет': 'Тёплая плёнка'})),
        'Тёплая плёнка',
      );
      expect(deviceSummary(_photo()), isNull);
      expect(presetOf(_photo()), isNull);
    });
  });

  testWidgets('share card shows the title and the shooting lines', (
    tester,
  ) async {
    await _openShareCard(tester);

    expect(find.byType(RecipeShareCard), findsOneWidget);
    expect(find.text('SHOT FROM A RECIPE'), findsOneWidget);
    expect(find.text('Freckled close-up'), findsOneWidget);
    expect(find.text('Xiaomi 15 · Portrait mode, 3× lens'), findsOneWidget);
    expect(find.text('ISO Auto · f2.0'), findsOneWidget);
    expect(find.text('Preset: Leica Authentic or no filter'), findsOneWidget);
    expect(find.text('SHOTBOOK'), findsOneWidget);
    expect(find.text('Recipe in SHOTBOOK'), findsOneWidget);
    expect(find.text('QR'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('share renders the card to a PNG and opens the share sheet', (
    tester,
  ) async {
    final temp = Directory.systemTemp.createTempSync('shotbook_share_test');
    addTearDown(() => temp.deleteSync(recursive: true));
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => temp.path,
    );
    final shared = <MethodCall>[];
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shared.add(call);
        return 'dev.fluttercommunity.plus/share/unavailable';
      },
    );
    addTearDown(() {
      messenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
      messenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      );
    });

    await _openShareCard(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text('Share'));
      for (var i = 0; i < 50 && shared.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    });
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    final args = Map<String, Object?>.from(shared.single.arguments as Map);
    expect(args['text'], 'Recipe from SHOTBOOK');
    final paths = List<String>.from(args['paths'] as List);
    expect(paths.single, endsWith('shotbook-recipe.png'));
    final png = File(paths.single).readAsBytesSync();
    // PNG signature, 1080 px wide (360 logical × 3).
    expect(png.sublist(1, 4), 'PNG'.codeUnits);
    final width = (png[16] << 24) | (png[17] << 16) | (png[18] << 8) | png[19];
    expect(width, 1080);
    expect(find.byType(SnackBar), findsNothing);
  });
}

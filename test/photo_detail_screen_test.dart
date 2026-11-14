import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/l10n/language_provider.dart';

void main() {
  testWidgets('opening a photo shows pose, camera and editing notes', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLanguageProvider.overrideWithValue('en')],
        child: ShotbookApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('photo-portrait-01')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo-portrait-01')));
    await tester.pumpAndSettle();

    // Graphite section labels are mono caps.
    expect(find.text('POSE'), findsOneWidget);
    expect(find.text('CAMERA SETTINGS'), findsOneWidget);
    expect(find.text('COLOR / EDITING'), findsOneWidget);
    expect(find.text('Freckled close-up'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Focal length'), findsOneWidget);
    expect(find.text('Preset'), findsOneWidget);
    expect(find.text('Camera guide: Xiaomi 15'), findsOneWidget);
    final credit = tester.widget<Text>(find.byKey(const Key('photo-credit')));
    expect(credit.textSpan!.toPlainText(), contains('dvanzuijlekom'));
    expect(credit.textSpan!.toPlainText(), contains('Flickr'));
  });
}

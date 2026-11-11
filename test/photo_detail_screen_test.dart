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

    await tester.tap(find.byKey(const ValueKey('photo-portrait-studio-light')));
    await tester.pumpAndSettle();

    expect(find.text('Pose'), findsOneWidget);
    expect(find.text('Camera settings'), findsOneWidget);
    expect(find.text('Color / editing'), findsOneWidget);
    expect(find.text('Body position'), findsOneWidget);
    expect(find.text('Focal length'), findsOneWidget);
    expect(find.text('Preset'), findsOneWidget);
    expect(
      find.textContaining(
        'commons.wikimedia.org/wiki/File:Photographer-studio-1893.jpg',
      ),
      findsOneWidget,
    );
  });
}

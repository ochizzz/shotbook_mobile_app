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

    await tester.ensureVisible(
      find.byKey(const ValueKey('photo-us--Keh6vLM7w0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo-us--Keh6vLM7w0')));
    await tester.pumpAndSettle();

    // Graphite section labels are mono caps.
    expect(find.text('POSE'), findsOneWidget);
    expect(find.text('CAMERA SETTINGS'), findsOneWidget);
    expect(find.text('COLOR / EDITING'), findsOneWidget);
    expect(find.text('Freckles in her palms'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Focal length'), findsOneWidget);
    expect(find.text('Preset'), findsOneWidget);
    expect(find.text('Camera guide: Your phone'), findsOneWidget);
    final credit = tester.widget<Text>(find.byKey(const Key('photo-credit')));
    expect(credit.textSpan!.toPlainText(), contains('Zulmaury Saavedra'));
    expect(credit.textSpan!.toPlainText(), contains('Unsplash'));
  });

  testWidgets('swiping moves to the next and previous photo', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLanguageProvider.overrideWithValue('en')],
        child: ShotbookApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('photo-us--Keh6vLM7w0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('photo-us--Keh6vLM7w0')));
    await tester.pumpAndSettle();
    expect(find.text('Freckles in her palms'), findsOneWidget);
    // "Repeat this shot" is the main sticky action, "Show pose" sits inline.
    expect(
      tester.widget(find.byKey(const Key('repeat-shot'))),
      isA<FilledButton>(),
    );
    expect(find.byKey(const Key('show-pose')), findsOneWidget);

    await tester.fling(
      find.byKey(const Key('photo-pages')),
      const Offset(-400, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.text('Freckles in her palms'), findsNothing);

    await tester.fling(
      find.byKey(const Key('photo-pages')),
      const Offset(400, 0),
      1500,
    );
    await tester.pumpAndSettle();
    expect(find.text('Freckles in her palms'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

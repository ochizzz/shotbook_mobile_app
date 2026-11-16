import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/features/camera/presentation/camera_screen.dart';
import 'package:shotbook/l10n/language_provider.dart';

void main() {
  testWidgets('photo page links to its phone guide and back to a recipe', (
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
    await tester.ensureVisible(find.byKey(const Key('open-device-guide')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-device-guide')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('NOTHING'), findsOneWidget);
    await tester.scrollUntilVisible(
      // Graphite section labels are mono caps.
      find.text('SHOT RECIPES FOR THIS PHONE'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CameraDeviceScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final ex = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey &&
          '${(w.key as ValueKey).value}'.startsWith('device-example-'),
    );
    await tester.tap(ex.first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('CAMERA SETTINGS'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/app/router.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';
import 'package:shotbook/features/pose/presentation/show_pose_screen.dart';
import 'package:shotbook/l10n/language_provider.dart';

void main() {
  final catalog = [
    for (final photo in seedPhotoReferences) photo.localized('en'),
  ];

  test('pose sequence starts with the photo, then its category', () {
    final sequence = poseSequence(catalog, 'portrait-01');
    expect(sequence.first.id, 'portrait-01');
    expect(sequence.length, maxPoseSequence);
    expect(sequence.map((photo) => photo.id).toSet().length, sequence.length);
    for (final photo in sequence.skip(1)) {
      expect(photo.category, 'Portrait');
      expect(photo.poseData, isNotEmpty);
    }
    expect(poseSequence(catalog, 'no-such-photo'), isEmpty);
  });

  testWidgets('pose screen shows the pose notes and steps through poses', (
    tester,
  ) async {
    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLanguageProvider.overrideWithValue('en')],
        child: ShotbookApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/photos/portrait-01/pose');
    await tester.pumpAndSettle();

    final sequence = poseSequence(catalog, 'portrait-01');
    final n = sequence.length;
    expect(find.text('POSE 1 / $n'), findsOneWidget);
    expect(find.byKey(const Key('pose-photo')), findsOneWidget);
    // Labels are accent caps, values big text.
    expect(find.text('LIGHT'), findsOneWidget);
    expect(
      find.text('Soft window light or overcast sky, face turned toward it'),
      findsOneWidget,
    );
    expect(find.text('ANGLE'), findsOneWidget);
    expect(find.text('Camera at eye level'), findsOneWidget);
    expect(
      find.text('Show this screen to the person you are photographing'),
      findsOneWidget,
    );
    expect(find.text('Next pose'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pose-next')));
    await tester.pumpAndSettle();
    expect(find.text('POSE 2 / $n'), findsOneWidget);
    final second = sequence[1].poseData.entries.first;
    expect(find.text(second.key.toUpperCase()), findsWidgets);
    expect(find.text(second.value), findsOneWidget);
    expect(find.text('Camera at eye level'), findsNothing);

    for (var i = 2; i < n; i++) {
      await tester.tap(find.byKey(const Key('pose-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('POSE $n / $n'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Next pose'), findsNothing);

    await tester.tap(find.byKey(const Key('pose-next')));
    await tester.pumpAndSettle();
    expect(find.byType(ShowPoseScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('close button leaves the pose screen', (tester) async {
    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLanguageProvider.overrideWithValue('en')],
        child: ShotbookApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    router.push('/photos/street-01/pose');
    await tester.pumpAndSettle();
    expect(find.byType(ShowPoseScreen), findsOneWidget);

    await tester.tap(find.byKey(const Key('pose-close')));
    await tester.pumpAndSettle();
    expect(find.byType(ShowPoseScreen), findsNothing);
  });
}

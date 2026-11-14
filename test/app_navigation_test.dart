import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/l10n/language_provider.dart';

void main() {
  testWidgets('bottom navigation opens four honest destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLanguageProvider.overrideWithValue('en')],
        child: ShotbookApp(),
      ),
    );

    expect(find.text('Discover'), findsWidgets);

    // Phones live in a small dropdown on Discover.
    await tester.tap(find.byKey(const Key('phone-filter')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('phone-search')), 'S23 Ultra');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('phone-option-samsung-s23-ultra')));
    await tester.pumpAndSettle();
    expect(find.text('Samsung Galaxy S23 Ultra'), findsOneWidget);
    await tester.tap(find.byKey(const Key('phone-filter-guide')));
    await tester.pumpAndSettle();
    expect(find.text('10 MP periscope · 230 mm'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Shot recipes for this phone'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Shot recipes for this phone'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The Camera tab opens the camera full screen.
    await tester.tap(find.text('Camera').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('camera-unavailable')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Feed').last);
    await tester.pumpAndSettle();
    expect(find.text('Community feed is not connected'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Your profile starts with an account'), findsOneWidget);

    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();
    expect(find.text('Find a frame'), findsOneWidget);
  });
}

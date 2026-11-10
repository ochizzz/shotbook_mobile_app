import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';

void main() {
  testWidgets('bottom navigation opens four honest destinations', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(child: ShotbookApp()));

    expect(find.text('Discover'), findsWidgets);

    await tester.tap(find.text('Camera').last);
    await tester.pumpAndSettle();
    expect(find.text('Camera guide'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'S23 Ultra');
    await tester.pumpAndSettle();
    expect(find.text('Galaxy S23 Ultra'), findsOneWidget);
    await tester.tap(find.byKey(const Key('camera-device-samsung-s23-ultra')));
    await tester.pumpAndSettle();
    expect(find.text('10 MP periscope · 230 mm'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Photo examples'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Photo examples'), findsOneWidget);
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

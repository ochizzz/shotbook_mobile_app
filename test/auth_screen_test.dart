import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/auth/presentation/auth_screen.dart';

void main() {
  testWidgets('invalid email is rejected before an auth request', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );

    await tester.enterText(find.byKey(const Key('auth-email')), 'not-an-email');
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'long-enough',
    );
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.byKey(const Key('auth-error')), findsNothing);
  });

  testWidgets('demo mode never reports a successful sign-in', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );

    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'person@example.test',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'long-enough',
    );
    await tester.tap(find.byKey(const Key('auth-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sign-in is unavailable'), findsOneWidget);
    expect(
      find.text(
        'Browsing works in demo mode. Configure Supabase to use accounts.',
      ),
      findsOneWidget,
    );
  });
}

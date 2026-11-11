import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/l10n/language_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the app is Russian by default', (tester) async {
    await tester.pumpWidget(ProviderScope(child: ShotbookApp()));
    await tester.pumpAndSettle();

    expect(find.text('Найди свой кадр'), findsOneWidget);
    expect(find.text('Обзор'), findsWidgets);
    expect(find.text('Find a frame'), findsNothing);

    await tester.tap(find.text('Камера').last);
    await tester.pumpAndSettle();
    expect(find.text('Гид по камере'), findsOneWidget);
  });

  testWidgets('language can be switched in profile settings and is saved', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(child: ShotbookApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('language-setting')));
    await tester.tap(find.byKey(const Key('language-setting')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language-en')));
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsWidgets);
    expect(find.text('Обзор'), findsNothing);
    expect(await loadSavedLanguage(), 'en');
  });

  testWidgets('a saved language is used on the next start', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [initialLanguageProvider.overrideWithValue('en')],
        child: ShotbookApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Find a frame'), findsOneWidget);
  });
}

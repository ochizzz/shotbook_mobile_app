import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/app/theme.dart';
import 'package:shotbook/features/challenges/application/streak_provider.dart';
import 'package:shotbook/features/challenges/domain/daily_picks.dart';
import 'package:shotbook/features/challenges/presentation/challenges_screen.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';
import 'package:shotbook/features/feed/presentation/create_post_screen.dart';
import 'package:shotbook/l10n/language_provider.dart';
import 'package:shotbook/shared/services/feature_flags.dart';

/// Saturday; the week of the "Golden hour" challenge.
final _now = DateTime(2026, 11, 14, 12);

class _FixedStreak extends StreakNotifier {
  _FixedStreak(this.days);

  final Set<DateTime> days;

  @override
  Set<DateTime> build() => days;
}

Future<void> _pumpChallenges(
  WidgetTester tester, {
  String language = 'en',
  Set<DateTime> activeDays = const {},
  bool community = true,
}) async {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/challenges',
    routes: [
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
      GoRoute(
        path: '/photos/:photoId',
        builder: (context, state) =>
            Text('photo ${state.pathParameters['photoId']}'),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) =>
            Text('create ${state.uri.queryParameters['challenge']}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        initialLanguageProvider.overrideWithValue(language),
        communityEnabledProvider.overrideWithValue(community),
        challengesClockProvider.overrideWithValue(() => _now),
        streakHistoryProvider.overrideWith(() => _FixedStreak(activeDays)),
      ],
      child: MaterialApp.router(
        theme: shotbookDarkTheme,
        routerConfig: router,
        locale: Locale(language),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('while the community is closed there is no Join button', (
    tester,
  ) async {
    await _pumpChallenges(tester, community: false);
    expect(find.byKey(const Key('challenge-join')), findsNothing);
    expect(find.text('Entries open soon'), findsOneWidget);
    expect(find.byKey(const Key('recipe-of-the-day')), findsOneWidget);
  });

  testWidgets('shows the challenge, the week, the recipe and the best', (
    tester,
  ) async {
    await _pumpChallenges(
      tester,
      activeDays: {
        DateTime(2026, 11, 9),
        DateTime(2026, 11, 10),
        DateTime(2026, 11, 11),
      },
    );

    expect(find.text('Challenges'), findsOneWidget);
    expect(find.text('CHALLENGE · 5 DAYS'), findsOneWidget);
    expect(find.text('Golden hour'), findsOneWidget);
    expect(find.text('Be the first'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
    expect(find.text('YOUR STREAK'), findsOneWidget);
    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(day), findsOneWidget, reason: day);
    }
    expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));
    expect(find.text('RECIPE OF THE DAY'), findsOneWidget);
    final recipe = recipeOfTheDay([
      for (final photo in seedPhotoReferences) photo.localized('en'),
    ], _now)!;
    expect(find.text(recipe.title), findsOneWidget);
    expect(find.text('BEST OF THE WEEK'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('recipe-of-the-day')));
    await tester.pumpAndSettle();
    expect(find.text('photo ${recipe.id}'), findsOneWidget);
  });

  testWidgets('Join opens a new post with the challenge preselected', (
    tester,
  ) async {
    await _pumpChallenges(tester);
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.tap(find.byKey(const Key('challenge-join')));
    await tester.pumpAndSettle();
    expect(find.text('create golden-hour'), findsOneWidget);
  });

  testWidgets('the best of the week opens a photo', (tester) async {
    await _pumpChallenges(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('photo-us--Keh6vLM7w0')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('photo-us--Keh6vLM7w0')));
    await tester.pumpAndSettle();
    expect(find.text('photo us--Keh6vLM7w0'), findsOneWidget);
  });

  testWidgets('is in Russian', (tester) async {
    await _pumpChallenges(
      tester,
      language: 'ru',
      activeDays: {DateTime(2026, 11, 14)},
    );

    expect(find.text('Челленджи'), findsOneWidget);
    expect(find.text('ЧЕЛЛЕНДЖ · 5 ДНЕЙ'), findsOneWidget);
    expect(find.text('Золотой час'), findsOneWidget);
    expect(find.text('Будь первым'), findsOneWidget);
    expect(find.text('Участвовать'), findsOneWidget);
    expect(find.text('ВАША СЕРИЯ'), findsOneWidget);
    for (final day in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']) {
      expect(find.text(day), findsOneWidget, reason: day);
    }
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('РЕЦЕПТ ДНЯ'), findsOneWidget);
    expect(find.text('ЛУЧШЕЕ ЗА НЕДЕЛЮ'), findsOneWidget);
  });

  testWidgets('a new post shows the preselected challenge', (tester) async {
    Future<void> pump(String? key) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLanguageProvider.overrideWithValue('en'),
          communityEnabledProvider.overrideWithValue(true),
        ],
        child: MaterialApp(
          theme: shotbookDarkTheme,
          home: CreatePostScreen(key: ValueKey(key), challengeKey: key),
        ),
      ),
    );

    await pump('golden-hour');
    expect(find.text('Challenge: Golden hour'), findsOneWidget);
    await pump('not-a-challenge');
    expect(find.byKey(const Key('post-challenge')), findsNothing);
    await pump(null);
    expect(find.byKey(const Key('post-challenge')), findsNothing);
  });

  group('in the app', () {
    testWidgets('without storage there is no streak and nothing breaks', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLanguageProvider.overrideWithValue('en'),
            communityEnabledProvider.overrideWithValue(true),
          ],
          child: ShotbookApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('streak-badge')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the streak badge is hidden for now', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [initialLanguageProvider.overrideWithValue('en')],
          child: ShotbookApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('streak-badge')), findsNothing);
    });

    testWidgets('opening the app starts a streak; the badge opens Challenges', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            initialLanguageProvider.overrideWithValue('en'),
            communityEnabledProvider.overrideWithValue(true),
            streakBadgeEnabledProvider.overrideWithValue(true),
          ],
          child: ShotbookApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1-day streak'), findsOneWidget);
      await tester.tap(find.byKey(const Key('streak-badge')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('challenge-card')), findsOneWidget);
      expect(find.text('Challenges'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(streakPreferenceKey), hasLength(1));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/challenges/domain/challenge.dart';
import 'package:shotbook/features/challenges/domain/daily_picks.dart';
import 'package:shotbook/features/challenges/presentation/challenge_text.dart';
import 'package:shotbook/features/discover/data/seed_photo_references.dart';
import 'package:shotbook/features/discover/domain/photo_reference.dart';
import 'package:shotbook/l10n/ru_strings.dart';

PhotoReference community(
  String id, {
  required DateTime createdAt,
  int views = 0,
  String? challengeKey,
  bool hidden = false,
}) => PhotoReference(
  id: id,
  title: id,
  description: '',
  imageUrl: 'https://example.com/$id.jpg',
  category: 'Street',
  sourcePage: '',
  credit: 'member',
  license: 'User submitted',
  sourceType: 'community',
  createdAt: createdAt,
  viewCount: views,
  challengeKey: challengeKey,
  isHidden: hidden,
);

void main() {
  group('weekly challenge rotation', () {
    test('the same challenge runs Monday to Sunday', () {
      final monday = challengeForDate(DateTime(2026, 11, 9, 0, 1));
      for (var day = 9; day <= 15; day++) {
        expect(challengeForDate(DateTime(2026, 11, day, 23, 59)), monday);
      }
      expect(challengeForDate(DateTime(2026, 11, 16)), isNot(monday));
    });

    test('rotates through every challenge, one per week, then repeats', () {
      final start = DateTime(2026, 11, 9, 12);
      final seen = [
        for (var week = 0; week < weeklyChallenges.length; week++)
          challengeForDate(start.add(Duration(days: 7 * week))),
      ];
      expect(
        seen.map((c) => c.key).toSet(),
        hasLength(weeklyChallenges.length),
      );
      expect(
        challengeForDate(
          start.add(Duration(days: 7 * weeklyChallenges.length)),
        ),
        seen.first,
      );
      // Continuous over New Year (ISO week 53 → 1) and before the start.
      expect(
        challengeWeekIndex(DateTime(2027, 1, 4)) -
            challengeWeekIndex(DateTime(2026, 12, 28)),
        1,
      );
      expect(challengeWeekIndex(DateTime(2026, 11, 8)), -1);
      expect(challengeForDate(DateTime(2026, 11, 8)), weeklyChallenges.last);
    });

    test('challenges have unique storable keys and 5 days', () {
      final keys = weeklyChallenges.map((c) => c.key).toList();
      expect(keys.toSet(), hasLength(keys.length));
      for (final challenge in weeklyChallenges) {
        expect(challenge.key, matches(RegExp(r'^[a-z0-9-]{1,40}$')));
        expect(challenge.days, 5);
        expect(challengeByKey(challenge.key), challenge);
        expect(
          seedPhotoReferences.where((p) => p.category == challenge.category),
          isNotEmpty,
          reason: challenge.category,
        );
      }
      expect(challengeByKey('nope'), isNull);
      expect(challengeByKey(null), isNull);
    });

    test('every challenge title and description is translated', () {
      for (final challenge in weeklyChallenges) {
        expect(ruStrings[challenge.title], isNotNull, reason: challenge.title);
        expect(
          ruStrings[challenge.description],
          isNotNull,
          reason: challenge.description,
        );
      }
    });
  });

  group('recipe of the day', () {
    test('is a curated photo, the same all day', () {
      final morning = recipeOfTheDay(
        seedPhotoReferences,
        DateTime(2026, 11, 14, 0, 5),
      );
      final night = recipeOfTheDay(
        seedPhotoReferences,
        DateTime(2026, 11, 14, 23, 55),
      );
      expect(morning, isNotNull);
      expect(morning!.sourceType, 'curated');
      expect(night!.id, morning.id);
    });

    test('changes from day to day and ignores catalog order', () {
      final ids = [
        for (var day = 0; day < 14; day++)
          recipeOfTheDay(
            seedPhotoReferences,
            DateTime(2026, 11, 1).add(Duration(days: day)),
          )!.id,
      ];
      expect(ids.toSet(), hasLength(14));
      final today = DateTime(2026, 11, 14, 12);
      expect(
        recipeOfTheDay(seedPhotoReferences.reversed.toList(), today)!.id,
        recipeOfTheDay(seedPhotoReferences, today)!.id,
      );
    });

    test('skips community photos and an empty catalog', () {
      final now = DateTime(2026, 11, 14);
      expect(recipeOfTheDay(const [], now), isNull);
      expect(recipeOfTheDay([community('c1', createdAt: now)], now), isNull);
    });
  });

  group('best of the week', () {
    final now = DateTime(2026, 11, 14, 12);

    test('recent community photos by views, then newest', () {
      final catalog = [
        ...seedPhotoReferences,
        community(
          'old',
          createdAt: now.subtract(const Duration(days: 8)),
          views: 99,
        ),
        community(
          'a',
          createdAt: now.subtract(const Duration(days: 1)),
          views: 3,
        ),
        community(
          'b',
          createdAt: now.subtract(const Duration(days: 2)),
          views: 10,
        ),
        community(
          'c',
          createdAt: now.subtract(const Duration(hours: 2)),
          views: 3,
        ),
        community('hidden', createdAt: now, views: 50, hidden: true),
      ];
      expect(bestOfWeek(catalog, now).map((p) => p.id), ['b', 'c', 'a']);
    });

    test('tops up with the most viewed curated photos', () {
      final curated = [
        seedPhotoReferences[0].copyWith(viewCount: 5),
        seedPhotoReferences[1].copyWith(viewCount: 40),
        seedPhotoReferences[2].copyWith(viewCount: 12),
        seedPhotoReferences[3],
      ];
      final catalog = [
        ...curated,
        community('fresh', createdAt: now.subtract(const Duration(days: 1))),
      ];
      expect(bestOfWeek(catalog, now).map((p) => p.id), [
        'fresh',
        curated[1].id,
        curated[2].id,
        curated[0].id,
      ]);
      expect(bestOfWeek(curated, now), hasLength(4));
      expect(
        bestOfWeek(curated, now, exclude: {curated[1].id}).map((p) => p.id),
        isNot(contains(curated[1].id)),
      );
    });
  });

  group('challenge entries', () {
    final now = DateTime(2026, 11, 14);
    final challenge = challengeByKey('golden-hour')!;

    test('count photos tagged with the challenge key', () {
      final catalog = [
        ...seedPhotoReferences,
        community('e1', createdAt: now, challengeKey: 'golden-hour', views: 1),
        community('e2', createdAt: now, challengeKey: 'golden-hour', views: 7),
        community('other', createdAt: now, challengeKey: 'shadows'),
        // The same challenge eight weeks earlier: a past run.
        community(
          'past',
          createdAt: now.subtract(const Duration(days: 56)),
          challengeKey: 'golden-hour',
          views: 99,
        ),
      ];
      expect(challengeEntries(catalog, challenge, now: now).map((p) => p.id), [
        'e2',
        'e1',
      ]);
      expect(challengeEntries(catalog, challenge), hasLength(3));
      final collage = challengeCollage(catalog, challenge, now: now);
      expect(collage.map((p) => p.id).take(2), ['e2', 'e1']);
      expect(collage, hasLength(3));
      expect(collage[2].category, challenge.category);
    });

    test('a Monday-morning entry counts for the new week', () {
      final monday = DateTime(2026, 11, 9, 0, 30);
      final catalog = [
        community('monday', createdAt: monday, challengeKey: 'golden-hour'),
        community(
          'sunday',
          createdAt: DateTime(2026, 11, 8, 23, 30),
          challengeKey: 'golden-hour',
        ),
      ];
      expect(challengeEntries(catalog, challenge, now: now).map((p) => p.id), [
        'monday',
      ]);
    });

    test('collage falls back to the challenge category', () {
      final collage = challengeCollage(seedPhotoReferences, challenge);
      expect(collage, hasLength(3));
      expect(collage.every((p) => p.category == challenge.category), isTrue);
    });

    test('reads challenge_key from the backend', () {
      final photo = PhotoReference.fromJson({
        'id': '3f1c6a0e-0000-4000-8000-000000000001',
        'challenge_key': 'golden-hour',
        'translations': {
          'en': {'title': 'Sunset'},
        },
      });
      expect(photo.challengeKey, 'golden-hour');
      expect(photo.localized('en').challengeKey, 'golden-hour');
      expect(photo.copyWith(viewCount: 3).challengeKey, 'golden-hour');
    });
  });

  test('Russian plural forms', () {
    expect(russianPluralForm(1), PluralForm.one);
    expect(russianPluralForm(21), PluralForm.one);
    expect(russianPluralForm(11), PluralForm.many);
    expect(russianPluralForm(3), PluralForm.few);
    expect(russianPluralForm(22), PluralForm.few);
    expect(russianPluralForm(12), PluralForm.many);
    expect(russianPluralForm(5), PluralForm.many);
    expect(russianPluralForm(128), PluralForm.many);
    expect(russianPluralForm(0), PluralForm.many);
  });
}

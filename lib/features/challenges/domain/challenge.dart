import 'streak.dart';

/// A themed weekly challenge. Definitions live in the app; entries are
/// community photos tagged with [key] (`photos.challenge_key`).
///
/// [title] and [description] are English UI text, translated through
/// `context.tr` (Russian in lib/l10n/ru_strings_challenges.dart).
class Challenge {
  const Challenge({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    this.days = 5,
  });

  /// Stable id stored with entries: lowercase letters, digits, dashes.
  final String key;
  final String title;
  final String description;

  /// Catalog category the card's collage is filled from.
  final String category;

  /// How long the challenge runs.
  final int days;
}

const weeklyChallenges = <Challenge>[
  Challenge(
    key: 'golden-hour',
    title: 'Golden hour',
    description:
        'Shoot in the warm, low light just after sunrise or before sunset.',
    category: 'Couple',
  ),
  Challenge(
    key: 'reflections',
    title: 'Reflections',
    description: 'Puddles, shop windows, mirrors: find a second picture inside the frame.',
    category: 'Street',
  ),
  Challenge(
    key: 'shadows',
    title: 'Shadows',
    description: 'Let hard light and deep shadows draw the shapes for you.',
    category: 'Lifestyle',
  ),
  Challenge(
    key: 'night-city',
    title: 'Night city',
    description: 'Street lights, neon and wet asphalt after dark.',
    category: 'Night',
  ),
  Challenge(
    key: 'silhouette',
    title: 'Silhouette',
    description:
        'Put your subject against a bright background and expose for the sky.',
    category: 'Full Body',
  ),
  Challenge(
    key: 'minimalism',
    title: 'Minimalism',
    description: 'One subject, plenty of empty space, nothing extra.',
    category: 'Product',
  ),
  Challenge(
    key: 'motion',
    title: 'Motion',
    description: 'Freeze it or let it blur: show that something is moving.',
    category: 'Car',
  ),
  Challenge(
    key: 'window-light',
    title: 'Window light',
    description: 'Soft side light from a single window, nothing else.',
    category: 'Portrait',
  ),
];

/// Monday of the launch week (ISO week 46 of 2026). The rotation starts
/// here with the first challenge and moves on every Monday.
final challengeRotationStart = DateTime.utc(2026, 11, 9);

/// Weeks (Monday to Sunday, as ISO weeks) since [challengeRotationStart];
/// negative before it. Counted continuously, so the rotation does not jump
/// at New Year the way ISO week numbers do.
int challengeWeekIndex(DateTime now) {
  final days = weekStart(now).difference(challengeRotationStart).inDays;
  // Floor division; Dart's % is never negative for a positive divisor.
  return (days - days % DateTime.daysPerWeek) ~/ DateTime.daysPerWeek;
}

/// The challenge running in the week of [now].
Challenge challengeForDate(DateTime now) =>
    weeklyChallenges[challengeWeekIndex(now) % weeklyChallenges.length];

/// The challenge with [key], or null for an unknown or empty key.
Challenge? challengeByKey(String? key) {
  if (key == null || key.isEmpty) return null;
  for (final challenge in weeklyChallenges) {
    if (challenge.key == key) return challenge;
  }
  return null;
}

import '../../discover/domain/photo_reference.dart';
import 'challenge.dart';
import 'streak.dart';

// What the Challenges screen picks from the catalog: pure functions of the
// catalog and the date, so the same day always shows the same photos.

bool _isCurated(PhotoReference photo) =>
    photo.sourceType == 'curated' && !photo.isHidden;

bool _isCommunity(PhotoReference photo) =>
    photo.sourceType == 'community' && !photo.isHidden;

/// Days since 1970-01-01 for [now]'s local date.
int _dayNumber(DateTime now) =>
    calendarDay(now).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;

/// Recipe of the day: one curated photo per local date, the same all day.
/// Photos are ordered by id first, so a reordered catalog does not change
/// the pick. Consecutive days step through the catalog by a prime, which
/// visits every photo before repeating and changes the genre day to day.
PhotoReference? recipeOfTheDay(List<PhotoReference> catalog, DateTime now) {
  final curated = catalog.where(_isCurated).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  if (curated.isEmpty) return null;
  const step = 7919;
  return curated[(_dayNumber(now) * step) % curated.length];
}

/// Community photos entered into [challenge], most viewed first. With
/// [now], only this week's run counts: a challenge comes round again every
/// few weeks, and older entries belong to its earlier runs.
List<PhotoReference> challengeEntries(
  List<PhotoReference> catalog,
  Challenge challenge, {
  DateTime? now,
}) {
  final monday = now == null ? null : weekStart(now);
  // Local midnight of Monday, compared as an instant with server times.
  final since = monday == null
      ? null
      : DateTime(monday.year, monday.month, monday.day);
  return _sortedByViews(
    catalog.where(
      (photo) =>
          _isCommunity(photo) &&
          photo.challengeKey == challenge.key &&
          (since == null ||
              (photo.createdAt != null && !photo.createdAt!.isBefore(since))),
    ),
  );
}

/// Three photos for the challenge card: its own entries first, then
/// curated photos from the challenge's category (then any curated photo).
List<PhotoReference> challengeCollage(
  List<PhotoReference> catalog,
  Challenge challenge, {
  DateTime? now,
  int count = 3,
}) {
  final picked = <PhotoReference>[];
  void addFrom(Iterable<PhotoReference> photos) {
    for (final photo in photos) {
      if (picked.length >= count) return;
      if (photo.imageUrl.isEmpty || picked.any((p) => p.id == photo.id)) {
        continue;
      }
      picked.add(photo);
    }
  }

  addFrom(challengeEntries(catalog, challenge, now: now));
  addFrom(
    catalog.where(
      (photo) => _isCurated(photo) && photo.category == challenge.category,
    ),
  );
  addFrom(catalog.where(_isCurated));
  return picked;
}

/// Best of the week: community photos from the last 7 days, most viewed
/// first (newest first on a tie). With fewer than 2 of them the section is
/// topped up to [fillTo] with the most viewed curated photos, so it is
/// never empty. [exclude] keeps e.g. the recipe of the day out.
List<PhotoReference> bestOfWeek(
  List<PhotoReference> catalog,
  DateTime now, {
  int limit = 6,
  int fillTo = 4,
  Set<String> exclude = const {},
}) {
  final since = now.subtract(const Duration(days: 7));
  final recent = catalog.where(
    (photo) =>
        _isCommunity(photo) &&
        !exclude.contains(photo.id) &&
        photo.createdAt != null &&
        photo.createdAt!.isAfter(since),
  );
  final best = _sortedByViews(recent).take(limit).toList();
  if (best.length >= 2) return best;
  final ids = best.map((photo) => photo.id).toSet();
  final curated = _sortedByViews(
    catalog.where(
      (photo) =>
          _isCurated(photo) &&
          !exclude.contains(photo.id) &&
          !ids.contains(photo.id),
    ),
  );
  return [...best, ...curated.take(fillTo - best.length)];
}

/// Most viewed first, then newest; otherwise the catalog order is kept
/// (List.sort is not stable, so the original index breaks ties).
List<PhotoReference> _sortedByViews(Iterable<PhotoReference> photos) {
  final indexed = photos.indexed.toList();
  indexed.sort((a, b) {
    final byViews = b.$2.viewCount.compareTo(a.$2.viewCount);
    if (byViews != 0) return byViews;
    final aTime = a.$2.createdAt, bTime = b.$2.createdAt;
    if (aTime != null && bTime != null) {
      final byTime = bTime.compareTo(aTime);
      if (byTime != 0) return byTime;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

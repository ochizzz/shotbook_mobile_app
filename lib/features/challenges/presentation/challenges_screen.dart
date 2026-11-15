import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/language_provider.dart';
import '../../../l10n/tr.dart';
import '../../../shared/widgets/graphite/graphite.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/data/seed_photo_references.dart';
import '../../discover/domain/photo_reference.dart';
import '../../discover/presentation/photo_grid_tile.dart';
import '../application/streak_provider.dart';
import '../domain/challenge.dart';
import '../domain/daily_picks.dart';
import 'challenge_text.dart';

/// Challenges (Penpot Graphite, "9 · Challenges"): the challenge of the
/// week, this week's streak, the recipe of the day and the week's best
/// community photos.
class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(challengesClockProvider)();
    final challenge = challengeForDate(now);
    final week = ref.watch(streakWeekProvider);
    final catalogState = ref.watch(remotePhotoCatalogProvider);
    final language = ref.watch(languageProvider);
    // Offline or failed: the bundled catalog, as elsewhere in the app.
    final List<PhotoReference>? catalog =
        catalogState.asData?.value ??
        (catalogState.hasError
            ? [
                for (final photo in seedPhotoReferences)
                  photo.localized(language),
              ]
            : null);
    final recipe = catalog == null ? null : recipeOfTheDay(catalog, now);
    final best = catalog == null
        ? const <PhotoReference>[]
        : bestOfWeek(catalog, now, exclude: {?recipe?.id});

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const Key('challenges-back'),
                    tooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                    onPressed: () => _goBack(context),
                    icon: const Icon(Icons.arrow_back, size: 24),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverList.list(
                children: [
                  Text(
                    context.tr('Challenges'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  _ChallengeCard(
                    challenge: challenge,
                    entries: catalog == null
                        ? null
                        : challengeEntries(catalog, challenge, now: now).length,
                    collage: catalog == null
                        ? const []
                        : challengeCollage(catalog, challenge, now: now),
                  ),
                  const SizedBox(height: 24),
                  SectionLabel(context.tr('Your streak')),
                  const SizedBox(height: 10),
                  _WeekRow(active: week),
                  const SizedBox(height: 28),
                  _RecipeOfTheDay(photo: recipe),
                  const SizedBox(height: 40),
                  SectionLabel(context.tr('Best of the week')),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                40 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childCount: best.length,
                itemBuilder: (context, index) =>
                    PhotoGridTile(photo: best[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _goBack(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // Opened from a link with nothing underneath.
      GoRouter.maybeOf(context)?.go('/discover');
    }
  }
}

/// Surface card: kicker, title, entries, "Join" and a three-photo collage.
class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.entries,
    required this.collage,
  });

  final Challenge challenge;

  /// Photos entered so far; null while the catalog loads.
  final int? entries;
  final List<PhotoReference> collage;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('challenge-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: ShotbookColors.surface,
        borderRadius: shotbookCardRadius,
        border: Border.all(color: ShotbookColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // One line; shrinks rather than wraps on narrow phones.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    challengeKicker(context, challenge.days),
                    style: ShotbookText.kicker.copyWith(
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(challenge.title),
                  key: const Key('challenge-title'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: shotbookTitleFont,
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    letterSpacing: -0.2,
                    height: 1.2,
                    color: ShotbookColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 16,
                  child: entries == null
                      ? null
                      : Text(
                          participantPhotos(context, entries!),
                          key: const Key('challenge-entries'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.2,
                            color: ShotbookColors.secondary,
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                FilledButton(
                  key: const Key('challenge-join'),
                  onPressed: () => context.push(
                    '/create?challenge=${Uri.encodeQueryComponent(challenge.key)}',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: shotbookShape,
                    textStyle: const TextStyle(
                      fontFamily: shotbookBodyFont,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  child: Text(context.tr('Join')),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _Collage(photos: collage),
        ],
      ),
    );
  }
}

/// One tall photo and two small ones (52×108 | 48×52 over 48×52).
class _Collage extends StatelessWidget {
  const _Collage({required this.photos});

  final List<PhotoReference> photos;

  static const _placeholders = [
    ShotbookColors.placeholder,
    Color(0xFF303338),
    Color(0xFF26282C),
  ];

  Widget _tile(BuildContext context, int index, double width, double height) {
    final photo = index < photos.length ? photos[index] : null;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: shotbookBorderRadius,
        child: Material(
          color: _placeholders[index],
          child: photo == null
              ? null
              : InkWell(
                  key: ValueKey('challenge-collage-${photo.id}'),
                  onTap: () => context.push('/photos/${photo.id}'),
                  child: Semantics(
                    label: photo.title,
                    child: PhotoReferenceImage(photo: photo, thumbnail: true),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tile(context, 0, 52, 108),
        const SizedBox(width: 8),
        Column(
          children: [
            _tile(context, 1, 48, 52),
            const SizedBox(height: 4),
            _tile(context, 2, 48, 52),
          ],
        ),
      ],
    );
  }
}

/// Seven 30 px circles, Monday to Sunday: amber with a check when the app
/// was used that day, an outline otherwise.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.active});

  final List<bool> active;

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.tr('Mon'),
      context.tr('Tue'),
      context.tr('Wed'),
      context.tr('Thu'),
      context.tr('Fri'),
      context.tr('Sat'),
      context.tr('Sun'),
    ];
    return Padding(
      // 47 px steps on a 360 px screen, as in the design.
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        key: const Key('streak-week'),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < labels.length; i++)
            _Day(label: labels[i], active: i < active.length && active[i]),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      checked: active,
      excludeSemantics: true,
      child: SizedBox(
        width: 30,
        child: Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? ShotbookColors.accent : null,
                border: active
                    ? null
                    : Border.all(color: ShotbookColors.border),
              ),
              child: active
                  ? const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: ShotbookColors.background,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: ShotbookText.data.copyWith(
                letterSpacing: 0,
                color: active
                    ? ShotbookColors.primary
                    : ShotbookColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Large photo with viewfinder ticks and the "RECIPE OF THE DAY" tag, then
/// title, phone · lens · ISO · preset, and the exposure in mono.
class _RecipeOfTheDay extends StatelessWidget {
  const _RecipeOfTheDay({required this.photo});

  /// Null while the catalog loads (the frame shows without text).
  final PhotoReference? photo;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    final meta = photo == null ? '' : _recipeMeta(context, photo);
    final data = photo == null ? '' : _exposure(photo);
    final frame = ClipRRect(
      borderRadius: shotbookCardRadius,
      child: AspectRatio(
        aspectRatio: 320 / 170,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: ShotbookColors.placeholder),
            if (photo != null) PhotoReferenceImage(photo: photo),
            const ViewfinderTicks(inset: 10, length: 14),
            Positioned(
              left: 14,
              top: 17,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  // Keeps the amber tag readable on bright photos.
                  color: ShotbookColors.background.withValues(alpha: 0.72),
                  borderRadius: shotbookTagRadius,
                ),
                child: Text(
                  context.tr('Recipe of the day').toUpperCase(),
                  style: ShotbookText.kicker.copyWith(
                    letterSpacing: 0.8,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (photo == null) return frame;
    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('recipe-of-the-day'),
          borderRadius: shotbookCardRadius,
          onTap: () => context.push('/photos/${photo.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              frame,
              const SizedBox(height: 12),
              Text(
                photo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: ShotbookColors.primary,
                ),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.2,
                    color: ShotbookColors.secondary,
                  ),
                ),
              ],
              if (data.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  data,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ShotbookText.data.copyWith(
                    letterSpacing: 0.3,
                    color: ShotbookColors.tertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

bool _has(String? value) => value != null && value.trim().isNotEmpty;

String _iso(String value) {
  final text = value.trim();
  return text.toUpperCase().startsWith('ISO') ? text : 'ISO $text';
}

/// "f/2.0 (fixed), f/2.8 in Portrait" → "f/2.0": the data line stays short.
String _short(String value) {
  final text = value.trim();
  final cut = text.indexOf(RegExp(r' \(|,|;'));
  return cut > 0 ? text.substring(0, cut).trim() : text;
}

String? _presetName(PhotoReference photo) {
  for (final value in [
    photo.presetName,
    photo.editingData['Preset'],
    photo.editingData['Пресет'],
  ]) {
    if (_has(value)) return value!.trim();
  }
  return null;
}

/// "Pixel 8 Pro · 1x · ISO 100 · preset “Warm film”".
String _recipeMeta(BuildContext context, PhotoReference photo) {
  final preset = _presetName(photo);
  final lens = _has(photo.focalLength) ? photo.focalLength : photo.camera;
  return [
    if (_has(photo.device)) photo.device!.trim(),
    if (_has(lens)) lens!.trim(),
    if (_has(photo.iso)) _iso(photo.iso!),
    if (preset != null) context.tr('preset “{name}”', {'name': preset}),
  ].join(' · ');
}

/// "ISO 100 · 1/250 · f1.7".
String _exposure(PhotoReference photo) => [
  if (_has(photo.iso)) _iso(_short(photo.iso!)),
  if (_has(photo.shutterSpeed)) _short(photo.shutterSpeed!),
  if (_has(photo.aperture)) _short(photo.aperture!),
].join(' · ');

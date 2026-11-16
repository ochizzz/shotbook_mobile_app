import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/services/supabase_providers.dart';
import '../../../shared/services/unsplash_tracking.dart';
import '../../../shared/widgets/graphite/graphite.dart';
import '../../../shared/widgets/photo_credit.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../../shared/widgets/source_badge.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/data/seed_photo_references.dart';
import '../../discover/domain/photo_reference.dart';
import '../../saved/application/saved_photo_provider.dart';
import '../../share/domain/shooting_summary.dart';
import 'metadata_section.dart';

/// Camera settings keys whose numeric values are shown monospaced.
const _shootingKeys = {
  'Focal length',
  'ISO',
  'Shutter speed',
  'Aperture',
  'Exposure compensation',
};

/// Recipe detail (Penpot "2 · Recipe detail"): full-bleed photo with the
/// shooting line, title, pose / camera / editing rows and a sticky bar with
/// "Repeat this shot" and share. Swipe left / right for the next / previous
/// photo of the list the user came from.
class PhotoDetailScreen extends ConsumerStatefulWidget {
  const PhotoDetailScreen({required this.photoId, super.key});

  final String photoId;

  @override
  ConsumerState<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends ConsumerState<PhotoDetailScreen> {
  /// The swipe order, fixed on first build so the pages don't reshuffle.
  List<PhotoReference>? _sequence;
  PageController? _pages;

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  List<PhotoReference> _sequenceFor(List<PhotoReference> catalog) {
    // The filtered Discover list when the photo is in it, else the catalog.
    final filtered = ref.read(filteredPhotoReferencesProvider).asData?.value;
    if (filtered != null && filtered.any((p) => p.id == widget.photoId)) {
      return filtered;
    }
    return catalog;
  }

  @override
  Widget build(BuildContext context) {
    final photoId = widget.photoId;
    final catalogState = ref.watch(remotePhotoCatalogProvider);
    if (catalogState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (catalogState.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Photo unavailable'))),
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(photoCatalogSourceProvider),
            child: Text(context.tr('Could not load this photo. Try again.')),
          ),
        ),
      );
    }
    final catalog = catalogState.asData?.value ?? seedPhotoReferences;
    if (!catalog.any((photo) => photo.id == photoId)) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Photo unavailable'))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.tr('This photo is not in the catalog.')),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(context.tr('Go back')),
              ),
            ],
          ),
        ),
      );
    }

    // Pick up language changes and fresh rows without changing the order.
    final byId = {for (final p in catalog) p.id: p};
    final sequence = (_sequence ??= _sequenceFor(
      catalog,
    )).map((p) => byId[p.id] ?? p).toList();
    _pages ??= PageController(
      initialPage: sequence.indexWhere((p) => p.id == photoId),
    );
    return PageView.builder(
      key: const Key('photo-pages'),
      controller: _pages,
      itemCount: sequence.length,
      itemBuilder: (context, index) => _PhotoRecipePage(
        key: ValueKey(sequence[index].id),
        photo: sequence[index],
      ),
    );
  }
}

class _PhotoRecipePage extends ConsumerStatefulWidget {
  const _PhotoRecipePage({required this.photo, super.key});

  final PhotoReference photo;

  @override
  ConsumerState<_PhotoRecipePage> createState() => _PhotoRecipePageState();
}

class _PhotoRecipePageState extends ConsumerState<_PhotoRecipePage> {
  /// Server total after this open was counted; null until it is known.
  int? _views;
  bool _viewRecorded = false;

  void _recordViewOnce(PhotoReference photo) {
    if (_viewRecorded) return;
    _viewRecorded = true;
    final remoteId = photo.remoteId;
    final repository = ref.read(remotePhotoRepositoryProvider);
    if (remoteId == null || repository == null || !isUuid(remoteId)) return;
    repository
        .recordView(remoteId)
        .then((total) {
          if (mounted) setState(() => _views = total);
        })
        .catchError((Object _) {
          // Counting a view is best effort; the photo still opens.
        });
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photo;
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordViewOnce(photo));
    final views = _views ?? photo.viewCount;
    final savedState = ref.watch(savedPhotoIdsProvider);
    final savedIds = savedState.asData?.value ?? const <String>{};
    final isSaved =
        savedIds.contains(photo.id) ||
        (photo.remoteId != null && savedIds.contains(photo.remoteId));
    final textTheme = Theme.of(context).textTheme;
    final note = textTheme.bodySmall?.copyWith(color: ShotbookColors.secondary);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _RecipeHero(
                photo: photo,
                isSaved: isSaved,
                onToggleSave: () {
                  if (!isSaved) {
                    trackUnsplashUse(ref.read(supabaseClientProvider), photo);
                  }
                  ref
                      .read(savedPhotoIdsProvider.notifier)
                      .toggle(photo.remoteId ?? photo.id);
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(photo.category).toUpperCase(),
                            style: ShotbookText.kicker,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.tr('Views: {n}', {
                            'n': '$views',
                          }).toUpperCase(),
                          key: const Key('photo-views'),
                          style: ShotbookText.section,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(photo.title, style: textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    Text(
                      photo.description,
                      style: textTheme.bodyLarge?.copyWith(
                        color: ShotbookColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      key: const Key('show-pose'),
                      onPressed: () => context.push('/photos/${photo.id}/pose'),
                      icon: const Icon(Icons.accessibility_new, size: 20),
                      label: Text(context.tr('Show pose')),
                    ),
                    MetadataSection(title: 'Pose', values: photo.poseData),
                    MetadataSection(
                      title: 'Camera settings',
                      values: photo.cameraSettings,
                      monoKeys: _shootingKeys,
                    ),
                    if (photo.sourceType == 'curated') ...[
                      if (photo.deviceId != null)
                        _DeviceGuideRow(
                          deviceId: photo.deviceId!,
                          device: photo.device ?? '',
                        ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr(
                          'Suggested settings to repeat the shot on this phone, not the original camera data.',
                        ),
                        style: note,
                      ),
                    ],
                    MetadataSection(
                      title: 'Color / editing',
                      values: photo.editingSettings,
                    ),
                    const SizedBox(height: 28),
                    SectionLabel(context.tr('Source')),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SourceBadge(photo: photo),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sourceExplanation(context, photo),
                      key: const Key('source-explanation'),
                      style: note,
                    ),
                    const SizedBox(height: 12),
                    if (photo.sourceType == 'curated')
                      PhotoCredit(photo: photo)
                    else
                      Text(
                        context.tr('Shared by a SHOTBOOK photographer'),
                        style: note,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _RecipeActionBar(photoId: photo.id),
      ),
    );
  }
}

/// 300 px photo with back and bookmark buttons, viewfinder ticks and the
/// shooting line ("ISO 100 · 1/60 · f1.8 · 26 mm") in the bottom-left.
class _RecipeHero extends StatelessWidget {
  const _RecipeHero({
    required this.photo,
    required this.isSaved,
    required this.onToggleSave,
  });

  final PhotoReference photo;
  final bool isSaved;
  final VoidCallback onToggleSave;

  static const height = 300.0;

  @override
  Widget build(BuildContext context) {
    // Buttons sit 8 px under the status bar (36 px from the top in Penpot).
    final buttonsTop = math.max(MediaQuery.paddingOf(context).top, 28) + 8;
    final exif = shootingSummary(photo);
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'photo-image-${photo.id}',
            child: ColoredBox(
              color: ShotbookColors.placeholder,
              child: PhotoReferenceImage(photo: photo),
            ),
          ),
          // Ticks frame the area under the buttons.
          Positioned(
            left: 0,
            right: 0,
            top: buttonsTop + 40,
            bottom: 0,
            child: const ViewfinderTicks(inset: 16, length: 14),
          ),
          if (exif != null)
            Positioned(
              left: 24,
              right: 48,
              bottom: 24,
              child: Text(
                exif,
                key: const Key('photo-exif'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ShotbookText.data.copyWith(
                  // Keeps the line readable over bright photos.
                  shadows: const [
                    Shadow(color: Color(0x99000000), blurRadius: 6),
                  ],
                ),
              ),
            ),
          Positioned(
            left: 12,
            top: buttonsTop - 4,
            child: _OverlayButton(
              icon: Icons.arrow_back,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/discover'),
            ),
          ),
          Positioned(
            right: 12,
            top: buttonsTop - 4,
            child: _OverlayButton(
              icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
              tooltip: isSaved
                  ? context.tr('Remove saved frame')
                  : context.tr('Save frame'),
              onPressed: onToggleSave,
            ),
          ),
        ],
      ),
    );
  }
}

/// 40×40 button over the photo: bg at 72 %, radius 10, icon 24 (48 px tap
/// target).
class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: 24,
    style: IconButton.styleFrom(
      backgroundColor: ShotbookColors.background.withValues(alpha: 0.72),
      foregroundColor: ShotbookColors.primary,
      fixedSize: const Size(40, 40),
      minimumSize: const Size(40, 40),
      padding: EdgeInsets.zero,
      shape: shotbookCardShape,
    ),
    icon: Icon(icon),
  );
}

/// "Camera guide: Xiaomi 15" row that opens the phone's camera guide.
class _DeviceGuideRow extends StatelessWidget {
  const _DeviceGuideRow({required this.deviceId, required this.device});

  final String deviceId;
  final String device;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('open-device-guide'),
    onTap: () => context.push('/camera/$deviceId'),
    child: Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ShotbookColors.border)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.photo_camera_outlined,
            size: 18,
            color: ShotbookColors.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr('Camera guide: {device}', {'device': device}),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ShotbookColors.primary,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 20,
            color: ShotbookColors.tertiary,
          ),
        ],
      ),
    ),
  );
}

/// Sticky 88 px bar: "Repeat this shot" and an outlined share button.
class _RecipeActionBar extends StatelessWidget {
  const _RecipeActionBar({required this.photoId});

  final String photoId;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: ShotbookColors.background,
      border: Border(top: BorderSide(color: ShotbookColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 19, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('repeat-shot'),
                onPressed: () => context.push('/photos/$photoId/repeat'),
                icon: const Icon(Icons.filter_center_focus, size: 20),
                label: Text(context.tr('Repeat this shot')),
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: context.tr('Share'),
              child: OutlinedButton(
                key: const Key('share-recipe'),
                onPressed: () => context.push('/photos/$photoId/share'),
                style: OutlinedButton.styleFrom(
                  fixedSize: const Size(56, 52),
                  minimumSize: const Size(56, 52),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.share_outlined, size: 24),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

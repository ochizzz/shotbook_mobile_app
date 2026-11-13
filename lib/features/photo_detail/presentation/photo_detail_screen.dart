import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/data/seed_photo_references.dart';
import '../../discover/domain/photo_reference.dart';
import '../../saved/application/saved_photo_provider.dart';
import 'metadata_section.dart';

class PhotoDetailScreen extends ConsumerStatefulWidget {
  const PhotoDetailScreen({required this.photoId, super.key});

  final String photoId;

  @override
  ConsumerState<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends ConsumerState<PhotoDetailScreen> {
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
    final matches = catalog.where((photo) => photo.id == photoId);
    if (matches.isEmpty) {
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

    final photo = matches.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordViewOnce(photo));
    final views = _views ?? photo.viewCount;
    final savedState = ref.watch(savedPhotoIdsProvider);
    final savedIds = savedState.asData?.value ?? const <String>{};
    final isSaved =
        savedIds.contains(photo.id) ||
        (photo.remoteId != null && savedIds.contains(photo.remoteId));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 380,
            pinned: false,
            backgroundColor: ShotbookColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'photo-image-${photo.id}',
                child: SizedBox.expand(
                  child: PhotoReferenceImage(photo: photo),
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: isSaved
                    ? context.tr('Remove saved frame')
                    : context.tr('Save frame'),
                onPressed: () => ref
                    .read(savedPhotoIdsProvider.notifier)
                    .toggle(photo.remoteId ?? photo.id),
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.tr(photo.category)} · ${context.tr('Views: {n}', {'n': '$views'})}',
                    key: const Key('photo-views'),
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: ShotbookColors.secondary),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    photo.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    photo.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: ShotbookColors.secondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    key: const Key('repeat-shot'),
                    onPressed: () => context.push('/photos/${photo.id}/repeat'),
                    icon: const Icon(Icons.filter_center_focus),
                    label: Text(context.tr('Repeat this shot')),
                  ),
                  MetadataSection(title: 'Pose', values: photo.poseData),
                  MetadataSection(
                    title: 'Camera settings',
                    values: photo.cameraSettings,
                  ),
                  if (photo.sourceType == 'curated') ...[
                    Text(
                      context.tr(
                        'Suggested settings to repeat the shot on this phone, not the original camera data.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                    if (photo.deviceId != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('open-device-guide'),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          onPressed: () =>
                              context.push('/camera/${photo.deviceId}'),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: Text(
                            context.tr('Camera guide: {device}', {
                              'device': photo.device ?? '',
                            }),
                          ),
                        ),
                      ),
                  ],
                  MetadataSection(
                    title: 'Color / editing',
                    values: photo.editingSettings,
                  ),
                  const SizedBox(height: 18),
                  if (photo.sourceType == 'curated') ...[
                    Text(
                      context.tr('Photo credit: {credit} · {license}', {
                        'credit': photo.credit,
                        'license': photo.license,
                      }),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('Source: Flickr via Openverse'),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                    if (photo.sourcePage.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SelectableText(
                        photo.sourcePage,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: ShotbookColors.secondary),
                      ),
                    ],
                  ] else
                    Text(
                      context.tr('Shared by a SHOTBOOK photographer'),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

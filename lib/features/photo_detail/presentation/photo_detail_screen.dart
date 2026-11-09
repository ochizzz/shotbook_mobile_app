import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/data/seed_photo_references.dart';
import '../../saved/application/saved_photo_provider.dart';
import 'metadata_section.dart';

class PhotoDetailScreen extends ConsumerWidget {
  const PhotoDetailScreen({required this.photoId, super.key});

  final String photoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogState = ref.watch(remotePhotoCatalogProvider);
    if (catalogState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (catalogState.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photo unavailable')),
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(remotePhotoCatalogProvider),
            child: const Text('Could not load this photo. Try again.'),
          ),
        ),
      );
    }
    final catalog = catalogState.asData?.value ?? seedPhotoReferences;
    final matches = catalog.where((photo) => photo.id == photoId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photo unavailable')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This photo is not in the catalog.'),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    final photo = matches.first;
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
                tooltip: isSaved ? 'Remove saved frame' : 'Save frame',
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
                    photo.category,
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
                  MetadataSection(title: 'Pose', values: photo.poseData),
                  MetadataSection(
                    title: 'Camera settings',
                    values: photo.cameraSettings,
                  ),
                  MetadataSection(
                    title: 'Color / editing',
                    values: photo.editingSettings,
                  ),
                  const SizedBox(height: 18),
                  if (photo.sourceType == 'curated') ...[
                    Text(
                      'Photo credit: ${photo.credit} · ${photo.license}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Source: Wikimedia Commons',
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
                      'Shared by a SHOTBOOK photographer',
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

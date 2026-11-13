import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/presentation/photo_grid_tile.dart';
import '../application/saved_photo_provider.dart';

class SavedPhotosScreen extends ConsumerWidget {
  const SavedPhotosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedState = ref.watch(savedPhotoIdsProvider);
    final catalogState = ref.watch(remotePhotoCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Saved'))),
      body: catalogState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : catalogState.hasError
          ? _SavedError(
              onRetry: () => ref.invalidate(photoCatalogSourceProvider),
            )
          : savedState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _SavedError(
                onRetry: () => ref.invalidate(savedPhotoIdsProvider),
              ),
              data: (ids) {
                final catalog = catalogState.asData?.value ?? const [];
                final savedPhotos = catalog
                    .where(
                      (photo) =>
                          ids.contains(photo.id) ||
                          (photo.remoteId != null &&
                              ids.contains(photo.remoteId)),
                    )
                    .toList();
                if (savedPhotos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bookmark_border,
                            color: ShotbookColors.secondary,
                            size: 28,
                          ),
                          const SizedBox(height: 14),
                          Text(context.tr('No saved frames yet.')),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(
                              'Save a photo to keep it here for later.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: ShotbookColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childCount: savedPhotos.length,
                        itemBuilder: (context, index) {
                          final photo = savedPhotos[index];
                          return PhotoGridTile(
                            key: ValueKey(photo.id),
                            photo: photo,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _SavedError extends StatelessWidget {
  const _SavedError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr('Saved photos could not be loaded.')),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.tr('Try again')),
            ),
          ],
        ),
      ),
    );
  }
}

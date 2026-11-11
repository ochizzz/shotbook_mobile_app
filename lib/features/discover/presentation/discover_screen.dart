import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../saved/application/saved_photo_provider.dart';
import '../application/discover_providers.dart';
import '../data/seed_photo_references.dart';
import 'discover_empty_state.dart';
import 'photo_grid_tile.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(discoverFiltersProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(discoverFiltersProvider);
    final photos = ref.watch(filteredPhotoReferencesProvider);
    final savedIds =
        ref.watch(savedPhotoIdsProvider).asData?.value ?? const <String>{};

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(remotePhotoCatalogProvider);
            await ref.read(remotePhotoCatalogProvider.future);
          },
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'SHOTBOOK',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontSize: 23, letterSpacing: 0.4),
                            ),
                          ),
                          IconButton(
                            key: const Key('open-saved'),
                            tooltip: context.tr('Saved photos'),
                            onPressed: () => context.push('/saved'),
                            icon: const Icon(Icons.bookmark_border),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        context.tr('Find a frame'),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const Key('discover-search-field'),
                        controller: _searchController,
                        onChanged: ref
                            .read(discoverFiltersProvider.notifier)
                            .setQuery,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: context.tr('Search photos or ideas'),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: context.tr('Clear search'),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(discoverFiltersProvider.notifier)
                                        .setQuery('');
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photoCategories.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final category = photoCategories[index];
                            return ChoiceChip(
                              label: Text(context.tr(category)),
                              selected: filters.category == category,
                              onSelected: (_) => ref
                                  .read(discoverFiltersProvider.notifier)
                                  .setCategory(category),
                              showCheckmark: false,
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: filters.category == category
                                        ? ShotbookColors.background
                                        : ShotbookColors.secondary,
                                  ),
                              selectedColor: ShotbookColors.primary,
                              backgroundColor: ShotbookColors.background,
                              side: BorderSide(
                                color: filters.category == category
                                    ? ShotbookColors.primary
                                    : ShotbookColors.border,
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              photos.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _CatalogError(
                    onRetry: () => ref.invalidate(remotePhotoCatalogProvider),
                  ),
                ),
                data: (items) => items.isEmpty
                    ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: DiscoverEmptyState(onClear: _clearFilters),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 12,
                          childCount: items.length,
                          itemBuilder: (context, index) {
                            final photo = items[index];
                            return PhotoGridTile(
                              key: ValueKey(photo.id),
                              photo: photo,
                              isSaved:
                                  savedIds.contains(photo.id) ||
                                  (photo.remoteId != null &&
                                      savedIds.contains(photo.remoteId)),
                              onSave: () => ref
                                  .read(savedPhotoIdsProvider.notifier)
                                  .toggle(photo.remoteId ?? photo.id),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 30),
          const SizedBox(height: 12),
          Text(context.tr('Could not load the catalog.')),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(context.tr('Try again'))),
        ],
      ),
    ),
  );
}

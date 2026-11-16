import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/widgets/graphite/graphite.dart';
import '../application/discover_providers.dart';
import '../data/seed_photo_references.dart';
import 'discover_empty_state.dart';
import 'phone_filter.dart';
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(photoCatalogSourceProvider);
            await ref.read(remotePhotoCatalogProvider.future);
          },
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // TopBar (64): wordmark, streak, saved.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('SHOTBOOK', style: ShotbookText.wordmark),
                        ),
                        const StreakBadge(),
                        IconButton(
                          key: const Key('open-saved'),
                          tooltip: context.tr('Saved photos'),
                          onPressed: () => context.push('/saved'),
                          icon: const Icon(Icons.bookmark_border, size: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
                        child: TextField(
                          key: const Key('discover-search-field'),
                          controller: _searchController,
                          onChanged: ref
                              .read(discoverFiltersProvider.notifier)
                              .setQuery,
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: context.tr('Find a frame'),
                            contentPadding: EdgeInsets.zero,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 14, right: 10),
                              child: Icon(Icons.search, size: 24),
                            ),
                            prefixIconConstraints: const BoxConstraints(),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: context.tr('Clear search'),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref
                                          .read(
                                            discoverFiltersProvider.notifier,
                                          )
                                          .setQuery('');
                                    },
                                    icon: const Icon(Icons.close, size: 20),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Chips run edge to edge, starting at the gutter.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: photoCategories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = photoCategories[index];
                      return GraphiteChip(
                        label: context.tr(category),
                        selected: filters.category == category,
                        onTap: () => ref
                            .read(discoverFiltersProvider.notifier)
                            .setCategory(category),
                      );
                    },
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 6, 20, 8),
                sliver: SliverToBoxAdapter(child: PhoneFilter()),
              ),
              photos.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _CatalogError(
                    onRetry: () => ref.invalidate(photoCatalogSourceProvider),
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
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childCount: items.length,
                          itemBuilder: (context, index) {
                            final photo = items[index];
                            return PhotoGridTile(
                              key: ValueKey(photo.id),
                              photo: photo,
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

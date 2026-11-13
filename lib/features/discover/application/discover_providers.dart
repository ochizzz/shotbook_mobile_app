import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/language_provider.dart';
import '../../../shared/services/supabase_providers.dart';
import '../data/photo_catalog_repository.dart';
import '../data/seed_photo_references.dart';
import '../data/supabase_photo_repository.dart';
import '../domain/photo_reference.dart';

final photoCatalogProvider = Provider<List<PhotoReference>>(
  (ref) => seedPhotoReferences,
);

/// The catalog as loaded: curated photos first (in their set order), then
/// community posts. Falls back to the bundled catalog when offline or when
/// the backend has no curated rows yet.
final photoCatalogSourceProvider = FutureProvider<List<PhotoReference>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return ref.watch(photoCatalogProvider);
  final photos = await SupabasePhotoRepository(client).loadPublicPhotos();
  if (photos.every((photo) => photo.sourceType != 'curated')) {
    return [...ref.watch(photoCatalogProvider), ...photos];
  }
  return photos;
});

/// The catalog in the interface language.
final remotePhotoCatalogProvider = FutureProvider<List<PhotoReference>>((
  ref,
) async {
  final language = ref.watch(languageProvider);
  final photos = await ref.watch(photoCatalogSourceProvider.future);
  return photos.map((photo) => photo.localized(language)).toList();
});

final discoverFiltersProvider =
    NotifierProvider<DiscoverFiltersNotifier, DiscoverFiltersState>(
      DiscoverFiltersNotifier.new,
    );

final filteredPhotoReferencesProvider =
    Provider<AsyncValue<List<PhotoReference>>>((ref) {
      final filters = ref.watch(discoverFiltersProvider);
      return ref
          .watch(remotePhotoCatalogProvider)
          .whenData(
            (photos) => filterPhotoReferences(
              photos,
              category: filters.category,
              query: filters.query,
            ),
          );
    });

class DiscoverFiltersState {
  const DiscoverFiltersState({this.category = 'All', this.query = ''});

  final String category;
  final String query;

  DiscoverFiltersState copyWith({String? category, String? query}) {
    return DiscoverFiltersState(
      category: category ?? this.category,
      query: query ?? this.query,
    );
  }
}

class DiscoverFiltersNotifier extends Notifier<DiscoverFiltersState> {
  @override
  DiscoverFiltersState build() => const DiscoverFiltersState();

  void setCategory(String category) {
    state = state.copyWith(category: category);
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void clear() {
    state = const DiscoverFiltersState();
  }
}

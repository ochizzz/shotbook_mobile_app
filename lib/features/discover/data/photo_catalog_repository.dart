import '../domain/photo_reference.dart';
import 'seed_photo_references.dart';

class PhotoCatalogRepository {
  const PhotoCatalogRepository({this.photos = seedPhotoReferences});

  final List<PhotoReference> photos;

  List<PhotoReference> getAll() => photos;

  List<PhotoReference> filter({String? category, String query = ''}) {
    return filterPhotoReferences(photos, category: category, query: query);
  }
}

List<PhotoReference> filterPhotoReferences(
  Iterable<PhotoReference> photos, {
  String? category,
  String query = '',
}) {
  final normalizedCategory = category == null || category == 'All'
      ? null
      : category;
  final normalizedQuery = query.trim().toLowerCase();

  return photos
      .where((photo) {
        final matchesCategory =
            normalizedCategory == null || photo.category == normalizedCategory;
        final searchableText =
            '${photo.title} ${photo.description} ${photo.category}'
                .toLowerCase();
        final matchesQuery =
            normalizedQuery.isEmpty || searchableText.contains(normalizedQuery);
        return matchesCategory && matchesQuery;
      })
      .toList(growable: false);
}

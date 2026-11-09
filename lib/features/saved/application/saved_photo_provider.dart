import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/discover/data/supabase_photo_repository.dart';
import '../../../features/discover/application/discover_providers.dart';
import '../../../features/auth/application/auth_providers.dart';
import '../../../shared/services/supabase_providers.dart';
import '../data/saved_photo_repository.dart';

final savedPhotoRepositoryProvider = Provider<SavedPhotoRepository>(
  (ref) => SavedPhotoRepository(),
);

final remotePhotoRepositoryProvider = Provider<SupabasePhotoRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabasePhotoRepository(client);
});

final savedPhotoIdsProvider =
    AsyncNotifierProvider<SavedPhotoIdsNotifier, Set<String>>(
      SavedPhotoIdsNotifier.new,
    );

final isPhotoSavedProvider = Provider.family<bool, String>((ref, photoId) {
  return ref.watch(savedPhotoIdsProvider).asData?.value.contains(photoId) ??
      false;
});

class SavedPhotoIdsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() {
    ref.watch(authStateProvider);
    return _loadIds();
  }

  Future<Set<String>> _loadIds() async {
    final localIds = await ref.read(savedPhotoRepositoryProvider).loadIds();
    final client = ref.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    final remoteRepository = ref.read(remotePhotoRepositoryProvider);
    if (user == null || remoteRepository == null) return localIds;
    try {
      final remoteIds = await remoteRepository.loadSavedIds(user.id);
      final photos = await ref.read(remotePhotoCatalogProvider.future);
      for (final localId in localIds) {
        final reference = photos
            .where((photo) => photo.id == localId || photo.remoteId == localId)
            .firstOrNull;
        final remoteId =
            reference?.remoteId ?? (isUuid(localId) ? localId : null);
        if (remoteId != null && !remoteIds.contains(remoteId)) {
          await remoteRepository.toggleSaved(
            userId: user.id,
            photoId: remoteId,
          );
          remoteIds.add(remoteId);
        }
      }
      return {...localIds, ...remoteIds};
    } catch (_) {
      // A failed sync must not hide local saves kept on the device.
      return localIds;
    }
  }

  Future<void> toggle(String photoId) async {
    final client = ref.read(supabaseClientProvider);
    final userId = client?.auth.currentUser?.id;
    final remoteRepository = ref.read(remotePhotoRepositoryProvider);
    state = await AsyncValue.guard(() async {
      if (userId != null && remoteRepository != null && isUuid(photoId)) {
        await remoteRepository.toggleSaved(userId: userId, photoId: photoId);
        final localIds = await ref.read(savedPhotoRepositoryProvider).loadIds();
        final photos =
            ref.read(remotePhotoCatalogProvider).asData?.value ?? const [];
        final legacyId = photos
            .where((photo) => photo.remoteId == photoId)
            .map((photo) => photo.id)
            .firstOrNull;
        if (localIds.contains(photoId)) {
          await ref.read(savedPhotoRepositoryProvider).toggle(photoId);
        }
        if (legacyId != null && localIds.contains(legacyId)) {
          await ref.read(savedPhotoRepositoryProvider).toggle(legacyId);
        }
        return _loadIds();
      }
      await ref.read(savedPhotoRepositoryProvider).toggle(photoId);
      return _loadIds();
    });
  }
}

bool isUuid(String value) => RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
).hasMatch(value);

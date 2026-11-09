import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/supabase_providers.dart';
import '../../../features/discover/domain/photo_reference.dart';
import '../data/profile_repository.dart';
import '../domain/shotbook_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : ProfileRepository(client);
});

final profileProvider = FutureProvider.family<ShotbookProfile?, String>((
  ref,
  userId,
) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository?.loadProfile(userId);
});

final profilePostsProvider =
    FutureProvider.family<List<PhotoReference>, String>((ref, userId) async {
      final repository = ref.watch(profileRepositoryProvider);
      return repository?.loadOwnPosts(userId) ?? const [];
    });

final profilePresetsProvider =
    FutureProvider.family<List<ProfilePreset>, String>((ref, userId) async {
      final repository = ref.watch(profileRepositoryProvider);
      return repository?.loadPresets(userId) ?? const [];
    });

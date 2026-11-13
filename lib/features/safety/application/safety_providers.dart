import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/safety_repository.dart';

final safetyRepositoryProvider = Provider<SafetyRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SafetyRepository(client);
});

final blockedUsersProvider = FutureProvider<List<BlockedUser>>((ref) async {
  final repository = ref.watch(safetyRepositoryProvider);
  if (repository == null || ref.watch(currentUserProvider) == null) {
    return const [];
  }
  return repository.loadBlocked();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/feed_repository.dart';
import '../domain/feed_post.dart';

final feedRepositoryProvider = Provider<FeedRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : FeedRepository(client);
});

final feedPostsProvider = FutureProvider<List<FeedPost>>((ref) async {
  final repository = ref.watch(feedRepositoryProvider);
  if (repository == null) return const [];
  final user = ref.watch(currentUserProvider);
  return repository.loadNewest(viewerId: user?.id);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/services/supabase_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/feed_repository.dart';
import '../domain/feed_post.dart';

const feedPageSize = 12;

final feedRepositoryProvider = Provider<FeedRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : FeedRepository(client);
});

/// The community feed, loaded a page at a time as the user scrolls.
final feedPostsProvider =
    AsyncNotifierProvider<FeedPostsNotifier, List<FeedPost>>(
      FeedPostsNotifier.new,
    );

class FeedPostsNotifier extends AsyncNotifier<List<FeedPost>> {
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedPost>> build() async {
    // Reload when the account changes: blocks and hidden posts depend on it.
    ref.watch(currentUserProvider);
    final repository = ref.watch(feedRepositoryProvider);
    _hasMore = true;
    _loadingMore = false;
    if (repository == null) return const [];
    final page = await repository.loadNewest(limit: feedPageSize);
    _hasMore = page.length == feedPageSize;
    return page;
  }

  /// Appends the next page. Safe to call repeatedly while scrolling.
  Future<void> loadMore() async {
    final current = state.asData?.value;
    final repository = ref.read(feedRepositoryProvider);
    if (current == null || repository == null || !_hasMore || _loadingMore) {
      return;
    }
    _loadingMore = true;
    try {
      final page = await repository.loadNewest(
        offset: current.length,
        limit: feedPageSize,
      );
      _hasMore = page.length == feedPageSize;
      final known = current.map((post) => post.photo.id).toSet();
      state = AsyncData([
        ...current,
        ...page.where((post) => !known.contains(post.photo.id)),
      ]);
    } catch (_) {
      // Keep what is shown; the next scroll tries again.
    } finally {
      _loadingMore = false;
    }
  }
}

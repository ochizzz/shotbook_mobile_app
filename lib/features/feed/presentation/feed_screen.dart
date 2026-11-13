import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/widgets/photo_actions_sheet.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../application/feed_providers.dart';
import '../domain/feed_post.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider);
    final repository = ref.watch(feedRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Feed')),
        actions: [
          IconButton(
            key: const Key('refresh-feed'),
            tooltip: context.tr('Refresh feed'),
            onPressed: () => ref.invalidate(feedPostsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-post'),
        onPressed: () => context.push('/create'),
        icon: const Icon(Icons.add),
        label: Text(context.tr('Post')),
      ),
      body: repository == null
          ? _FeedMessage(
              icon: Icons.cloud_off_outlined,
              title: context.tr('Community feed is not connected'),
              message: context.tr(
                'Add Supabase settings to load posts and publish your own photos.',
              ),
            )
          : posts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _FeedMessage(
                icon: Icons.error_outline,
                title: context.tr('Feed could not be loaded'),
                message: context.tr('Check your connection, then try again.'),
                action: TextButton(
                  onPressed: () => ref.invalidate(feedPostsProvider),
                  child: Text(context.tr('Try again')),
                ),
              ),
              data: (items) => items.isEmpty
                  ? _FeedMessage(
                      icon: Icons.photo_library_outlined,
                      title: context.tr('No community posts yet'),
                      message: context.tr(
                        'Be the first to share a photo and its shooting notes.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        try {
                          await ref
                              .refresh(feedPostsProvider.future)
                              .then<void>((_) {});
                        } catch (_) {
                          // The provider exposes the load error and retry action.
                        }
                      },
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          // Fetch the next page well before the end.
                          if (notification.metrics.extentAfter < 1200) {
                            ref.read(feedPostsProvider.notifier).loadMore();
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              FeedPostCard(post: items[index]),
                        ),
                      ),
                    ),
            ),
    );
  }
}

/// A feed post is a clean photo block. Author, views and actions open on a
/// long press.
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({required this.post, super.key});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: shotbookBorderRadius,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Material(
          color: ShotbookColors.card,
          child: InkWell(
            key: Key('post-${post.photo.id}'),
            onTap: () => context.push('/photos/${post.photo.id}'),
            onLongPress: () => showPhotoActions(
              context,
              photo: post.photo,
              author: '${post.authorName} (@${post.username})',
              extraActions: [
                if (post.photo.authorId != null)
                  PhotoSheetAction(
                    key: const Key('sheet-author'),
                    icon: Icons.person_outline,
                    label: context.tr('Author profile'),
                    onSelected: () =>
                        context.push('/users/${post.photo.authorId}'),
                  ),
              ],
            ),
            child: Semantics(
              label: post.photo.title,
              child: PhotoReferenceImage(photo: post.photo),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ShotbookColors.secondary, size: 30),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: ShotbookColors.secondary),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    ),
  );
}

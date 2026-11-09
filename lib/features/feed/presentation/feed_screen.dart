import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../auth/application/auth_providers.dart';
import '../../saved/application/saved_photo_provider.dart';
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
        title: const Text('Feed'),
        actions: [
          IconButton(
            key: const Key('refresh-feed'),
            tooltip: 'Refresh feed',
            onPressed: () => ref.invalidate(feedPostsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-post'),
        onPressed: () => context.push('/create'),
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: repository == null
          ? const _FeedMessage(
              icon: Icons.cloud_off_outlined,
              title: 'Community feed is not connected',
              message: 'Add Supabase settings to load posts and publish your own photos.',
            )
          : posts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _FeedMessage(
                icon: Icons.error_outline,
                title: 'Feed could not be loaded',
                message: 'Check your connection, then try again.',
                action: TextButton(
                  onPressed: () => ref.invalidate(feedPostsProvider),
                  child: const Text('Try again'),
                ),
              ),
              data: (items) => items.isEmpty
                  ? const _FeedMessage(
                      icon: Icons.photo_library_outlined,
                      title: 'No community posts yet',
                      message: 'Be the first to share a photo and its shooting notes.',
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
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 22),
                        itemBuilder: (context, index) =>
                            FeedPostCard(post: items[index]),
                      ),
                    ),
            ),
    );
  }
}

class FeedPostCard extends ConsumerWidget {
  const FeedPostCard({required this.post, super.key});

  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final repository = ref.watch(feedRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: ShotbookColors.surface,
              backgroundImage: post.avatarUrl == null
                  ? null
                  : CachedNetworkImageProvider(post.avatarUrl!),
              child: post.avatarUrl == null
                  ? const Icon(Icons.person_outline, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => context.push('/users/${post.photo.authorId}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '@${post.username}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                  ],
                ),
              ),
            ),
            if (post.photo.createdAt != null)
              Text(
                _timeAgo(post.photo.createdAt!),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: ShotbookColors.secondary),
              ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => context.push('/photos/${post.photo.id}'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 370,
              width: double.infinity,
              child: PhotoReferenceImage(photo: post.photo),
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              key: Key('like-${post.photo.id}'),
              tooltip: post.isLiked ? 'Unlike photo' : 'Like photo',
              onPressed: () async {
                if (user == null) {
                  context.push('/auth');
                  return;
                }
                if (repository == null) return;
                try {
                  await repository.setLiked(
                    userId: user.id,
                    photoId: post.photo.id,
                    liked: post.isLiked,
                  );
                  ref.invalidate(feedPostsProvider);
                } catch (error) {
                  if (context.mounted) _showError(context, error);
                }
              },
              icon: Icon(
                post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: post.isLiked ? Colors.redAccent : null,
              ),
            ),
            Text('${post.likeCount}'),
            const Spacer(),
            IconButton(
              key: Key('save-${post.photo.id}'),
              tooltip: 'Save photo',
              onPressed: () async {
                if (user == null) {
                  context.push('/auth');
                  return;
                }
                try {
                  await ref
                      .read(savedPhotoIdsProvider.notifier)
                      .toggle(post.photo.id);
                } catch (error) {
                  if (context.mounted) _showError(context, error);
                }
              },
              icon: Icon(
                ref.watch(isPhotoSavedProvider(post.photo.id))
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
            ),
          ],
        ),
        Text(post.photo.title, style: Theme.of(context).textTheme.titleMedium),
        if (post.photo.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            post.photo.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 6),
        Text(
          [
                post.photo.device,
                post.photo.camera,
                post.photo.focalLength,
                post.photo.iso == null ? null : 'ISO ${post.photo.iso}',
                post.photo.shutterSpeed,
                post.photo.aperture,
              ]
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .join(' · '),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: ShotbookColors.secondary),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'now';
    if (difference.inHours < 1) return '${difference.inMinutes}m';
    if (difference.inDays < 1) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${date.day}.${date.month}.${date.year}';
  }

  static void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
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

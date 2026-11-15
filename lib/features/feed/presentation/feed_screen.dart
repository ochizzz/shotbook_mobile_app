import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/services/feature_flags.dart';
import '../../../shared/widgets/graphite/graphite.dart';
import '../../../shared/widgets/photo_actions_sheet.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../../shared/widgets/source_badge.dart';
import '../application/feed_providers.dart';
import '../domain/feed_post.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(communityEnabledProvider)) return const _FeedComingSoon();
    final posts = ref.watch(feedPostsProvider);
    final repository = ref.watch(feedRepositoryProvider);

    Widget content() {
      if (repository == null) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _FeedMessage(
            icon: Icons.cloud_off_outlined,
            title: context.tr('Community feed is not connected'),
            message: context.tr(
              'Add Supabase settings to load posts and publish your own photos.',
            ),
          ),
        );
      }
      return posts.when(
        loading: () => const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (error, stackTrace) => SliverFillRemaining(
          hasScrollBody: false,
          child: _FeedMessage(
            icon: Icons.error_outline,
            title: context.tr('Feed could not be loaded'),
            message: context.tr('Check your connection, then try again.'),
            action: TextButton(
              onPressed: () => ref.invalidate(feedPostsProvider),
              child: Text(context.tr('Try again')),
            ),
          ),
        ),
        data: (items) => items.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: _FeedMessage(
                  icon: Icons.photo_library_outlined,
                  title: context.tr('No community posts yet'),
                  message: context.tr(
                    'Be the first to share a photo and its shooting notes.',
                  ),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: items.length,
                  itemBuilder: (context, index) =>
                      FeedPostCard(post: items[index]),
                ),
              ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create-post'),
        onPressed: () => context.push('/create'),
        icon: const Icon(Icons.add, size: 20),
        label: Text(context.tr('Post')),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            try {
              await ref.refresh(feedPostsProvider.future).then<void>((_) {});
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ScreenTitle(
                      context.tr('Feed'),
                      trailing: const StreakBadge(),
                    ),
                  ),
                ),
                content(),
              ],
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
      borderRadius: shotbookCardRadius,
      child: AspectRatio(
        aspectRatio: post.photo.imageAspectRatio,
        child: Material(
          color: ShotbookColors.placeholder,
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PhotoReferenceImage(photo: post.photo, thumbnail: true),
                  const ViewfinderTicks(),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: SourceBadge(photo: post.photo, compact: true),
                  ),
                ],
              ),
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

/// Shown on the Feed tab while the community is not open yet.
class _FeedComingSoon extends StatelessWidget {
  const _FeedComingSoon();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('feed-coming-soon'),
    body: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ScreenTitle(context.tr('Feed')),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('In development').toUpperCase(),
                      style: ShotbookText.kicker,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('Coming soon'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr(
                        'The feed with photos from SHOTBOOK photographers will open here.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: ShotbookColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/camera/presentation/camera_screen.dart';
import '../features/challenges/presentation/challenges_screen.dart';
import '../features/pose/presentation/show_pose_screen.dart';
import '../features/share/presentation/share_card_screen.dart';
import '../l10n/tr.dart';
import 'theme.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/update_password_screen.dart';
import '../features/feed/presentation/create_post_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/photo_detail/presentation/photo_detail_screen.dart';
import '../features/pro_camera/shoot_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/repeat_shot/presentation/repeat_shot_screen.dart';
import '../features/saved/presentation/saved_photos_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/discover',
    // Links from Supabase emails (confirm, reset) open the app on
    // com.shotbook.shotbook://login-callback. The Supabase SDK reads the link
    // itself; the router only has to land somewhere valid. The reset flow then
    // opens /set-password from the auth event (see ShotbookApp).
    redirect: (context, state) {
      final uri = state.uri;
      if (uri.host == 'login-callback' ||
          uri.scheme == 'com.shotbook.shotbook' ||
          uri.path == '/login-callback') {
        return '/discover';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => const DiscoverScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/challenges',
        builder: (context, state) => const ChallengesScreen(),
      ),
      // The Camera tab opens the camera full screen, without the tab bar.
      GoRoute(path: '/shoot', builder: (context, state) => const ShootScreen()),
      // All phones with their camera guides (opened from Discover).
      GoRoute(
        path: '/phones',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/camera/:deviceId',
        builder: (context, state) =>
            CameraDeviceScreen(deviceId: state.pathParameters['deviceId']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'blocked',
            builder: (context, state) => const BlockedUsersScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/set-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/create',
        // ?challenge=<key> enters the post into that weekly challenge.
        builder: (context, state) => CreatePostScreen(
          challengeKey: state.uri.queryParameters['challenge'],
        ),
      ),
      GoRoute(
        path: '/users/:profileId',
        builder: (context, state) =>
            ProfileScreen(profileId: state.pathParameters['profileId']),
      ),
      GoRoute(
        path: '/saved',
        builder: (context, state) => const SavedPhotosScreen(),
      ),
      GoRoute(
        path: '/photos/:photoId',
        builder: (context, state) =>
            PhotoDetailScreen(photoId: state.pathParameters['photoId']!),
        routes: [
          GoRoute(
            path: 'repeat',
            builder: (context, state) =>
                RepeatShotScreen(photoId: state.pathParameters['photoId']!),
          ),
          GoRoute(
            path: 'pose',
            builder: (context, state) =>
                ShowPoseScreen(photoId: state.pathParameters['photoId']!),
          ),
          GoRoute(
            path: 'share',
            builder: (context, state) =>
                ShareCardScreen(photoId: state.pathParameters['photoId']!),
          ),
        ],
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Tab 1 (Camera) is not a branch: it opens the camera over the app.
    final selected = navigationShell.currentIndex >= 1
        ? navigationShell.currentIndex + 1
        : navigationShell.currentIndex;
    void onTap(int index) {
      if (index == 1) {
        context.push('/shoot');
        return;
      }
      final branch = index > 1 ? index - 1 : index;
      navigationShell.goBranch(
        branch,
        initialLocation: branch == navigationShell.currentIndex,
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _GraphiteNavBar(
        selected: selected,
        onTap: onTap,
        items: [
          (Icons.grid_view_rounded, context.tr('Discover')),
          (Icons.photo_camera, context.tr('Camera')),
          (Icons.view_agenda, context.tr('Feed')),
          (Icons.person, context.tr('Profile')),
        ],
      ),
    );
  }
}

/// Graphite bottom nav: 1 px top rule, amber 28×2 indicator over the active
/// item, 22 px icons, Onest 500 11 labels, inactive items in tertiary grey.
class _GraphiteNavBar extends StatelessWidget {
  const _GraphiteNavBar({
    required this.selected,
    required this.onTap,
    required this.items,
  });

  final int selected;
  final ValueChanged<int> onTap;
  final List<(IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ShotbookColors.background,
        border: Border(top: BorderSide(color: ShotbookColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 71,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    label: items[i].$2,
                    child: InkResponse(
                      onTap: () => onTap(i),
                      highlightShape: BoxShape.rectangle,
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            width: i == selected ? 28 : 0,
                            height: 2,
                            color: ShotbookColors.accent,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  items[i].$1,
                                  size: 22,
                                  color: i == selected
                                      ? ShotbookColors.primary
                                      : ShotbookColors.tertiary,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  items[i].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: i == selected
                                        ? ShotbookColors.primary
                                        : ShotbookColors.tertiary,
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}

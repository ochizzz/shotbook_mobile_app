import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/camera/presentation/camera_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/update_password_screen.dart';
import '../features/feed/presentation/create_post_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/discover/presentation/discover_screen.dart';
import '../features/photo_detail/presentation/photo_detail_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/saved/presentation/saved_photos_screen.dart';

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
                path: '/camera',
                builder: (context, state) => const CameraScreen(),
                routes: [
                  GoRoute(
                    path: ':deviceId',
                    builder: (context, state) => CameraDeviceScreen(
                      deviceId: state.pathParameters['deviceId']!,
                    ),
                  ),
                ],
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
        path: '/set-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/create',
        builder: (context, state) => const CreatePostScreen(),
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
      ),
    ],
  );
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt_rounded),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.view_stream_outlined),
            selectedIcon: Icon(Icons.view_stream_rounded),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

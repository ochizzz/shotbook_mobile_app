import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/application/auth_providers.dart';

import 'router.dart';
import 'theme.dart';

class ShotbookApp extends ConsumerStatefulWidget {
  ShotbookApp({super.key, GoRouter? router})
    : router = router ?? createAppRouter();

  final GoRouter router;

  @override
  ConsumerState<ShotbookApp> createState() => _ShotbookAppState();
}

class _ShotbookAppState extends ConsumerState<ShotbookApp> {
  ProviderSubscription<AsyncValue<AuthState?>>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual(authStateProvider, (previous, next) {
      if (next.asData?.value?.event == AuthChangeEvent.passwordRecovery) {
        widget.router.push('/set-password');
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SHOTBOOK',
      debugShowCheckedModeBanner: false,
      theme: shotbookDarkTheme,
      routerConfig: widget.router,
    );
  }
}

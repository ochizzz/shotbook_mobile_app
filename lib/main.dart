import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'shared/services/supabase_config.dart';
import 'shared/services/supabase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  final config = ShotbookSupabaseConfig.fromEnvironment();
  var supabaseReady = false;
  if (config.isConfigured) {
    try {
      await Supabase.initialize(
        url: config.url!,
        publishableKey: config.anonKey!,
      );
      supabaseReady = true;
    } catch (error) {
      debugPrint('Supabase unavailable; using local demo data: $error');
    }
  }

  runApp(
    ProviderScope(
      overrides: [supabaseReadyProvider.overrideWithValue(supabaseReady)],
      child: const _ShotbookRoot(),
    ),
  );
}

class _ShotbookRoot extends StatelessWidget {
  const _ShotbookRoot();

  @override
  Widget build(BuildContext context) => ShotbookApp();
}

/// Starts Firebase Crashlytics when the app is configured for it. Missing
/// configuration must never prevent the app from launching.
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    if (kReleaseMode) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (error) {
    debugPrint('Firebase unavailable; crash reporting disabled: $error');
  }
}

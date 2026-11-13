import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'features/onboarding/onboarding.dart';
import 'l10n/language_provider.dart';
import 'shared/services/supabase_config.dart';
import 'shared/services/supabase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  final language = await loadSavedLanguage();
  final onboarded = await loadOnboardingDone();

  runApp(
    ProviderScope(
      overrides: [
        supabaseReadyProvider.overrideWithValue(supabaseReady),
        initialLanguageProvider.overrideWithValue(language),
        initialOnboardingDoneProvider.overrideWithValue(onboarded),
      ],
      child: const _ShotbookRoot(),
    ),
  );
}

class _ShotbookRoot extends StatelessWidget {
  const _ShotbookRoot();

  @override
  Widget build(BuildContext context) => ShotbookApp();
}

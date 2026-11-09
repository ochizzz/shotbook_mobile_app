import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

final supabaseConfigProvider = Provider<ShotbookSupabaseConfig>(
  (ref) => ShotbookSupabaseConfig.fromEnvironment(),
);

final supabaseReadyProvider = Provider<bool>((ref) => false);

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!ref.watch(supabaseReadyProvider)) return null;
  return Supabase.instance.client;
});

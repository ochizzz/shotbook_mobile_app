import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/shared/services/supabase_config.dart';

void main() {
  group('ShotbookSupabaseConfig', () {
    test('uses demo mode when credentials are absent', () {
      final config = ShotbookSupabaseConfig.fromValues('', '');

      expect(config.isConfigured, isFalse);
      expect(config.url, isNull);
      expect(config.anonKey, isNull);
    });

    test('accepts a valid project URL and public client key', () {
      final config = ShotbookSupabaseConfig.fromValues(
        'https://sample.supabase.co',
        'public-anon-key',
      );

      expect(config.isConfigured, isTrue);
      expect(config.url, 'https://sample.supabase.co');
      expect(config.anonKey, 'public-anon-key');
    });

    test('rejects a partial or malformed configuration', () {
      expect(
        ShotbookSupabaseConfig.fromValues(
          'https://sample.supabase.co',
          '',
        ).isConfigured,
        isFalse,
      );
      expect(
        ShotbookSupabaseConfig.fromValues(
          'not a url',
          'public-anon-key',
        ).isConfigured,
        isFalse,
      );
    });

    test('rejects modern Supabase secret API keys', () {
      expect(
        ShotbookSupabaseConfig.fromValues(
          'https://sample.supabase.co',
          'sb_secret_do_not_ship',
        ).isConfigured,
        isFalse,
      );
      expect(
        ShotbookSupabaseConfig.fromValues(
          'https://sample.supabase.co',
          'eyJhbGciOiJub25lIn0.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.signature',
        ).isConfigured,
        isFalse,
      );
    });
  });
}

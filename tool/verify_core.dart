import 'dart:io';

import 'package:shotbook/features/discover/domain/photo_reference.dart';
import 'package:shotbook/features/feed/data/image_upload_validation.dart';
import 'package:shotbook/shared/services/supabase_config.dart';

void _expect(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  _expect(
    !ShotbookSupabaseConfig.fromValues('', '').isConfigured,
    'Missing credentials should use demo mode.',
  );
  _expect(
    ShotbookSupabaseConfig.fromValues(
      'https://sample.supabase.co',
      'publishable-key',
    ).isConfigured,
    'A project URL and public client key should be accepted.',
  );
  _expect(
    !ShotbookSupabaseConfig.fromValues(
      'https://sample.supabase.co',
      'service_role_secret',
    ).isConfigured,
    'A service-role key must not be accepted by the app configuration.',
  );
  _expect(
    !ShotbookSupabaseConfig.fromValues(
      'https://sample.supabase.co',
      'sb_secret_do_not_ship',
    ).isConfigured,
    'A modern Supabase secret key must not be accepted by the app configuration.',
  );
  _expect(
    !ShotbookSupabaseConfig.fromValues(
      'https://sample.supabase.co',
      'eyJhbGciOiJub25lIn0.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.signature',
    ).isConfigured,
    'A legacy service-role JWT must not be accepted by the app configuration.',
  );
  _expect(
    ImageUploadValidation.validate('sample.jpg', [0xff, 0xd8, 0xff]) ==
        'image/jpeg',
    'A JPEG signature should be accepted.',
  );
  var mismatchRejected = false;
  try {
    ImageUploadValidation.validate('sample.jpg', [1, 2, 3]);
  } on FormatException {
    mismatchRejected = true;
  }
  _expect(
    mismatchRejected,
    'A file with a mismatched image signature should be rejected.',
  );
  var oversizedRejected = false;
  try {
    ImageUploadValidation.validate(
      'sample.png',
      List.filled(10 * 1024 * 1024 + 1, 0),
    );
  } on FormatException {
    oversizedRejected = true;
  }
  _expect(oversizedRejected, 'An image over 10 MiB should be rejected.');

  final photo = PhotoReference.fromJson({
    'id': '00000000-0000-4000-8000-000000000001',
    'legacy_id': 'catalog-photo',
    'title': 'Rain after dark',
    'description': 'Wet pavement.',
    'image_url': 'https://sample.test/photo.webp',
    'category': 'Street',
    'source_type': 'curated',
    'pose_data': {'Gaze': 'Ahead'},
    'editing_data': {'Preset': 'Night silver', 'Grain': '12'},
  });
  final restored = PhotoReference.fromJson(photo.toJson());
  _expect(photo.id == restored.id, 'Catalog slug should round trip.');
  _expect(
    photo.remoteId == restored.remoteId,
    'Database UUID should round trip.',
  );
  _expect(
    restored.editingSettings['Preset'] == 'Night silver',
    'Preset metadata should round trip.',
  );

  final schema = File('supabase/migrations/202611090001_shotbook_mvp.sql')
      .readAsStringSync();
  final catalogSeed = File(
    'supabase/migrations/202611090002_seed_curated_catalog.sql',
  ).readAsStringSync();
  _expect(
    schema.contains('enable row level security'),
    'All data tables should enable RLS.',
  );
  _expect(
    schema.contains('revoke all on table') &&
        schema.contains(
          'grant select on table public.photos to anon, authenticated',
        ) &&
        schema.contains(
          'grant insert, update, delete on table public.photos to authenticated',
        ),
    'Public tables should revoke default client privileges and explicitly grant only needed operations.',
  );
  _expect(
    schema.contains(
      'revoke all on tables from anon, authenticated, service_role',
    ),
    'Future public tables should not inherit broad Data API privileges.',
  );
  _expect(
    schema.contains('auth.uid() = user_id'),
    'Saved rows and likes should be user-owned.',
  );
  _expect(
    schema.contains("'photos', 'photos'") &&
        schema.contains("'avatars', 'avatars'"),
    'Both image buckets should be provisioned.',
  );
  _expect(
    RegExp(r"\('00000000-0000-4000-8000-0000000000[0-9]{2}'")
            .allMatches(catalogSeed)
            .length ==
        21,
    'The SQL migration should seed 21 curated photos.',
  );

  stderr.writeln('Core smoke checks passed.');
}

import 'dart:convert';
import 'dart:io';

import 'package:shotbook/features/discover/data/seed_photo_references.dart';

String _sql(String value) => "'${value.replaceAll("'", "''")}'";
String _optionalSql(String? value) =>
    value == null || value.trim().isEmpty ? 'null' : _sql(value);

void main() {
  final rows = <String>[];
  for (var index = 0; index < seedPhotoReferences.length; index++) {
    final photo = seedPhotoReferences[index];
    final stableId =
        '00000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}';
    final editing = {
      ...photo.editingData,
      if (photo.presetName != null) 'Preset': photo.presetName!,
    };
    final values = [
      _sql(stableId),
      _sql(photo.id),
      _sql(photo.title),
      _sql(photo.description),
      _sql(photo.imageUrl),
      _sql(photo.sourcePage),
      _sql(photo.credit),
      _sql(photo.license),
      _sql(photo.category),
      _sql('curated'),
      _optionalSql(photo.device),
      _optionalSql(photo.camera),
      _optionalSql(photo.focalLength),
      _optionalSql(photo.iso),
      _optionalSql(photo.shutterSpeed),
      _optionalSql(photo.aperture),
      _optionalSql(photo.whiteBalance),
      _optionalSql(photo.exposureCompensation),
      "'${jsonEncode(photo.poseData).replaceAll("'", "''")}'::jsonb",
      "'${jsonEncode(editing).replaceAll("'", "''")}'::jsonb",
    ];
    rows.add('(${values.join(', ')})');
  }

  final output =
      '''-- Curated reference catalog, generated from lib/features/discover/data/seed_photo_references.dart.
insert into public.photos (
  id, legacy_id, title, description, image_url, source_page, credit, license,
  category, source_type, device, camera, focal_length, iso, shutter_speed,
  aperture, white_balance, exposure_compensation, pose_data, editing_data
)
values
${rows.join(',\n')}
on conflict (legacy_id) do nothing;
''';
  File('supabase/migrations/202611090002_seed_curated_catalog.sql')
      .writeAsStringSync(output);
}

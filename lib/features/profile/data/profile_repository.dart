import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/discover/domain/photo_reference.dart';
import '../domain/shotbook_profile.dart';

class ProfileRepository {
  const ProfileRepository(this._client);

  final SupabaseClient _client;

  Future<ShotbookProfile?> loadProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : ShotbookProfile.fromJson(row);
  }

  Future<ShotbookProfile> updateProfile({
    required String userId,
    required String username,
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) async {
    final values = <String, dynamic>{
      'username': username.trim(),
      'display_name': displayName.trim(),
      'bio': bio.trim(),
    };
    if (avatarUrl != null) values['avatar_url'] = avatarUrl;
    final row = await _client
        .from('profiles')
        .update(values)
        .eq('id', userId)
        .select()
        .single();
    return ShotbookProfile.fromJson(row);
  }

  Future<List<PhotoReference>> loadOwnPosts(String userId) async {
    final rows = await _client
        .from('photos')
        .select()
        .eq('author_id', userId)
        .order('created_at', ascending: false);
    return rows.map((row) => PhotoReference.fromJson(row)).toList();
  }

  Future<List<ProfilePreset>> loadPresets(String userId) async {
    final rows = await _client
        .from('photos')
        .select('editing_data')
        .eq('author_id', userId);
    final values = <String, List<Map<String, String>>>{};
    for (final row in rows) {
      final editing = row['editing_data'];
      if (editing is! Map) continue;
      final settings = editing.map<String, String>(
        (key, value) => MapEntry('$key', '$value'),
      );
      final name = settings['Preset']?.trim();
      if (name == null || name.isEmpty) continue;
      values.putIfAbsent(name, () => []).add(settings);
    }
    return values.entries
        .map(
          (entry) => ProfilePreset(
            name: entry.key,
            photoCount: entry.value.length,
            settings: entry.value.first,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}

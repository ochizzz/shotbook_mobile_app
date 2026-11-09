import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/photo_reference.dart';

class SupabasePhotoRepository {
  const SupabasePhotoRepository(this._client);

  final SupabaseClient _client;

  Future<List<PhotoReference>> loadPublicPhotos() async {
    final rows = await _client
        .from('photos')
        .select()
        .order('created_at', ascending: false);
    return rows.map((row) => PhotoReference.fromJson(row)).toList();
  }

  Future<Set<String>> loadSavedIds(String userId) async {
    final rows = await _client
        .from('saved_photos')
        .select('photo_id')
        .eq('user_id', userId);
    return rows.map((row) => row['photo_id'] as String).toSet();
  }

  Future<void> toggleSaved({
    required String userId,
    required String photoId,
  }) async {
    final existing = await _client
        .from('saved_photos')
        .select('id')
        .eq('user_id', userId)
        .eq('photo_id', photoId)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('saved_photos')
          .delete()
          .eq('user_id', userId)
          .eq('photo_id', photoId);
    } else {
      await _client.from('saved_photos').insert({
        'user_id': userId,
        'photo_id': photoId,
      });
    }
  }
}

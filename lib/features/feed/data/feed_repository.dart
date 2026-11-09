import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/discover/domain/photo_reference.dart';
import '../domain/feed_post.dart';
import 'image_upload_validation.dart';

class FeedRepository {
  const FeedRepository(this._client);

  final SupabaseClient _client;

  Future<List<FeedPost>> loadNewest({String? viewerId}) async {
    final rows = await _client
        .from('photos')
        .select()
        .eq('source_type', 'community')
        .order('created_at', ascending: false);
    if (rows.isEmpty) return const [];

    final photos = rows.map((row) => PhotoReference.fromJson(row)).toList();
    final photoIds = photos.map((photo) => photo.id).toList();
    final authorIds = photos
        .map((photo) => photo.authorId)
        .whereType<String>()
        .toSet()
        .toList();
    final profiles = authorIds.isEmpty
        ? <dynamic>[]
        : await _client
              .from('profiles')
              .select('id, username, display_name, avatar_url')
              .inFilter('id', authorIds);
    final profileById = {
      for (final profile in profiles) profile['id'] as String: profile,
    };
    final likes = await _client
        .from('likes')
        .select('photo_id, user_id')
        .inFilter('photo_id', photoIds);
    final likesByPhoto = <String, List<dynamic>>{};
    for (final like in likes) {
      (likesByPhoto[like['photo_id'] as String] ??= []).add(like);
    }

    return photos.map((photo) {
      final profile = profileById[photo.authorId];
      final photoLikes = likesByPhoto[photo.id] ?? const [];
      return FeedPost(
        photo: photo,
        authorName: profile?['display_name'] as String? ?? 'SHOTBOOK member',
        username: profile?['username'] as String? ?? 'member',
        avatarUrl: profile?['avatar_url'] as String?,
        likeCount: photoLikes.length,
        isLiked:
            viewerId != null &&
            photoLikes.any((like) => like['user_id'] == viewerId),
      );
    }).toList();
  }

  Future<void> setLiked({
    required String userId,
    required String photoId,
    required bool liked,
  }) async {
    if (liked) {
      await _client
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('photo_id', photoId);
    } else {
      await _client
          .from('likes')
          .upsert(
            {'user_id': userId, 'photo_id': photoId},
            onConflict: 'user_id,photo_id',
            ignoreDuplicates: true,
          );
    }
  }

  Future<PhotoReference> createPost({
    required String userId,
    required String fileName,
    required List<int> bytes,
    required String title,
    required String description,
    required String category,
    required Map<String, String?> cameraSettings,
    required String? preset,
    required Map<String, String> editingSettings,
  }) async {
    final mimeType = ImageUploadValidation.validate(fileName, bytes);
    final extension = mimeType == 'image/jpeg'
        ? 'jpg'
        : mimeType.split('/').last;
    final path = '$userId/${DateTime.now().microsecondsSinceEpoch}.$extension';
    final storage = _client.storage.from('photos');
    await storage.uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(contentType: mimeType, upsert: false),
    );
    try {
      final row = await _client
          .from('photos')
          .insert({
            'title': title.trim(),
            'description': description.trim(),
            'image_url': storage.getPublicUrl(path),
            'storage_path': path,
            'category': category,
            'source_type': 'community',
            'author_id': userId,
            ...cameraSettings.map(
              (key, value) => MapEntry(
                key,
                value?.trim().isEmpty ?? true ? null : value!.trim(),
              ),
            ),
            'editing_data': {
              ...editingSettings,
              if (preset != null && preset.trim().isNotEmpty)
                'Preset': preset.trim(),
            },
          })
          .select()
          .single();
      return PhotoReference.fromJson(row);
    } catch (_) {
      await storage.remove([path]);
      rethrow;
    }
  }

  Future<void> deletePost(PhotoReference photo) async {
    await _client.from('photos').delete().eq('id', photo.remoteId ?? photo.id);
    if (photo.storagePath != null) {
      try {
        await _client.storage.from('photos').remove([photo.storagePath!]);
      } catch (_) {
        // The database row is already gone; an orphaned public object does not block deletion.
      }
    }
  }
}

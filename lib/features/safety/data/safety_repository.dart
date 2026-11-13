import 'package:supabase_flutter/supabase_flutter.dart';

/// Reasons a user can pick when reporting. Values match the database check.
const reportReasons = [
  'spam',
  'nudity',
  'violence',
  'harassment',
  'hate',
  'copyright',
  'other',
];

class BlockedUser {
  const BlockedUser({
    required this.id,
    required this.username,
    required this.displayName,
  });

  final String id;
  final String username;
  final String displayName;
}

class AlreadyReportedException implements Exception {
  const AlreadyReportedException();
}

/// Reports, blocks and account deletion.
class SafetyRepository {
  const SafetyRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Sign in first.');
    return id;
  }

  Future<void> report({
    String? photoId,
    String? userId,
    required String reason,
    String details = '',
  }) async {
    assert(photoId != null || userId != null);
    try {
      await _client.from('reports').insert({
        'reporter_id': _userId,
        'photo_id': ?photoId,
        'reported_user_id': ?userId,
        'reason': reason,
        if (details.trim().isNotEmpty) 'details': details.trim(),
      });
    } on PostgrestException catch (error) {
      // Unique index: one report per person per photo or user.
      if (error.code == '23505') throw const AlreadyReportedException();
      rethrow;
    }
  }

  Future<void> block(String userId) => _client.from('blocks').upsert({
    'blocker_id': _userId,
    'blocked_id': userId,
  }, ignoreDuplicates: true);

  Future<void> unblock(String userId) => _client
      .from('blocks')
      .delete()
      .eq('blocker_id', _userId)
      .eq('blocked_id', userId);

  Future<List<BlockedUser>> loadBlocked() async {
    final rows = await _client
        .from('blocks')
        .select('blocked_id, created_at')
        .eq('blocker_id', _userId)
        .order('created_at', ascending: false);
    if (rows.isEmpty) return const [];
    final ids = rows.map((row) => row['blocked_id'] as String).toList();
    final profiles = await _client
        .from('profiles')
        .select('id, username, display_name')
        .inFilter('id', ids);
    final byId = {for (final p in profiles) p['id'] as String: p};
    return [
      for (final id in ids)
        BlockedUser(
          id: id,
          username: byId[id]?['username'] as String? ?? 'member',
          displayName:
              byId[id]?['display_name'] as String? ?? 'SHOTBOOK member',
        ),
    ];
  }

  /// Deletes the signed-in account and everything it owns, then signs out.
  /// Storage files go first (the database cannot remove them by cascade).
  Future<void> deleteAccount() async {
    final userId = _userId;
    for (final bucket in ['photos', 'avatars']) {
      final storage = _client.storage.from(bucket);
      while (true) {
        final files = await storage.list(
          path: userId,
          searchOptions: const SearchOptions(limit: 100),
        );
        final paths = files
            .where((file) => file.id != null)
            .map((file) => '$userId/${file.name}')
            .toList();
        if (paths.isEmpty) break;
        await storage.remove(paths);
        if (files.length < 100) break;
      }
    }
    await _client.rpc('delete_my_account');
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // The account is already gone; only the local session remains.
    }
  }
}

import 'dart:convert';

class ShotbookSupabaseConfig {
  const ShotbookSupabaseConfig._({this.url, this.anonKey});

  factory ShotbookSupabaseConfig.fromValues(String url, String anonKey) {
    final normalizedUrl = url.trim();
    final normalizedKey = anonKey.trim();
    final parsedUrl = Uri.tryParse(normalizedUrl);
    final validUrl =
        parsedUrl != null &&
        (parsedUrl.scheme == 'https' || parsedUrl.scheme == 'http') &&
        parsedUrl.host.isNotEmpty;
    final validKey =
        normalizedKey.isNotEmpty && !_isPrivilegedKey(normalizedKey);

    if (!validUrl || !validKey) return const ShotbookSupabaseConfig._();
    return ShotbookSupabaseConfig._(url: normalizedUrl, anonKey: normalizedKey);
  }

  factory ShotbookSupabaseConfig.fromEnvironment() =>
      ShotbookSupabaseConfig.fromValues(
        const String.fromEnvironment('SUPABASE_URL'),
        const String.fromEnvironment('SUPABASE_ANON_KEY'),
      );

  final String? url;
  final String? anonKey;

  bool get isConfigured => url != null && anonKey != null;

  static bool _isPrivilegedKey(String key) {
    final normalizedKey = key.trim().toLowerCase();
    if (normalizedKey.startsWith('sb_secret_') ||
        normalizedKey.contains('service_role')) {
      return true;
    }
    final segments = key.trim().split('.');
    if (segments.length < 2) return false;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      return payload is Map && payload['role'] == 'service_role';
    } on FormatException {
      return false;
    }
  }
}

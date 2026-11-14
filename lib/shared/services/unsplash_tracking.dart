import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/discover/domain/photo_reference.dart';

/// Reports a "use" of an Unsplash photo (save, repeat shot) through the
/// `unsplash-download` edge function. Fire and forget: never blocks or
/// fails the user's action.
void trackUnsplashUse(SupabaseClient? client, PhotoReference photo) {
  if (client == null || !photo.isUnsplash) return;
  client.functions
      .invoke('unsplash-download', body: {'id': photo.unsplashId})
      .then<void>((_) {}, onError: (Object _) {});
}

/// Unsplash asks for these parameters on every link back to it.
String withUnsplashReferral(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'utm_source': 'shotbook',
          'utm_medium': 'referral',
        },
      )
      .toString();
}

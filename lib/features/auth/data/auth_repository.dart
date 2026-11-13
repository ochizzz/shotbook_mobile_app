import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(this._client);

  static const authRedirectTo = 'com.shotbook.shotbook://login-callback';

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirectTo,
      data: {
        'username': username.trim(),
        'display_name': displayName.trim(),
        // Sign-up requires accepting the terms and community rules.
        'terms_accepted_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  Future<void> resetPassword(String email) => _client.auth
      .resetPasswordForEmail(email.trim(), redirectTo: authRedirectTo);

  Future<void> signOut() => _client.auth.signOut();
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/services/supabase_providers.dart';
import '../application/auth_providers.dart';

enum _AuthMode { signIn, signUp, reset }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      setState(
        () => _error =
            'Sign-in is unavailable. Add Supabase settings to enable accounts.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      switch (_mode) {
        case _AuthMode.signIn:
          await repository.signIn(email: _email.text, password: _password.text);
          if (mounted) context.pop();
          break;
        case _AuthMode.signUp:
          final response = await repository.signUp(
            email: _email.text,
            password: _password.text,
            username: _username.text,
            displayName: _displayName.text.isEmpty
                ? _username.text
                : _displayName.text,
          );
          // For an already registered address Supabase answers with success
          // but an empty identities list, and sends no email.
          final alreadyRegistered = response.user?.identities?.isEmpty ?? false;
          if (mounted && alreadyRegistered) {
            setState(
              () => _error = 'This email is already registered. Sign in instead, or use "Forgot password?".',
            );
          } else if (mounted && response.session != null) {
            context.pop();
          } else if (mounted) {
            setState(
              () => _message =
                  'Check your email to confirm your account, then sign in.',
            );
          }
          break;
        case _AuthMode.reset:
          await repository.resetPassword(_email.text);
          if (mounted) {
            setState(
              () => _message =
                  'Password reset instructions were sent to your email.',
            );
          }
          break;
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyAuthError(Object error) {
    final text = error.toString();
    if (text.contains('over_email_send_rate_limit') ||
        text.contains('statusCode: 429')) {
      return 'Too many emails requested. Wait a minute, then use the newest email.';
    }
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup')) {
      return 'Could not reach Supabase. Check your connection and project settings.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == _AuthMode.signUp;
    final isReset = _mode == _AuthMode.reset;
    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SHOTBOOK',
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(letterSpacing: 2),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isReset
                          ? 'Reset password'
                          : isSignUp
                          ? 'Create your account'
                          : 'Welcome back',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isReset
                          ? 'We will email you a secure reset link.'
                          : 'Save references and share what you shoot.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                    const SizedBox(height: 28),
                    if (isSignUp) ...[
                      TextFormField(
                        key: const Key('auth-username'),
                        controller: _username,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 3
                            ? 'Use at least 3 characters.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        key: const Key('auth-display-name'),
                        controller: _displayName,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Display name (optional)',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      key: const Key('auth-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email address.'
                          : null,
                    ),
                    if (!isReset) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const Key('auth-password'),
                        controller: _password,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: (value) => value == null || value.length < 6
                            ? 'Use at least 6 characters.'
                            : null,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        key: const Key('auth-error'),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!, key: const Key('auth-message')),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      key: const Key('auth-submit'),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isReset
                                  ? 'Send reset link'
                                  : isSignUp
                                  ? 'Create account'
                                  : 'Sign in',
                            ),
                    ),
                    if (!isReset && !isSignUp)
                      TextButton(
                        onPressed: () => setState(() {
                          _mode = _AuthMode.reset;
                          _error = null;
                          _message = null;
                        }),
                        child: const Text('Forgot password?'),
                      ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _mode = isReset
                                  ? _AuthMode.signIn
                                  : isSignUp
                                  ? _AuthMode.signIn
                                  : _AuthMode.signUp;
                              _error = null;
                              _message = null;
                            }),
                      child: Text(
                        isReset
                            ? 'Back to sign in'
                            : isSignUp
                            ? 'Already have an account? Sign in'
                            : 'Create an account',
                      ),
                    ),
                    if (!ref.watch(supabaseReadyProvider))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Browsing works in demo mode. Configure Supabase to use accounts.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ShotbookColors.secondary),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

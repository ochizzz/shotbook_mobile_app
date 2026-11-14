import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/services/friendly_error.dart';
import '../../../shared/widgets/graphite/graphite.dart';
import '../../../shared/services/legal_links.dart';
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
  bool _acceptedTerms = false;
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
    if (_mode == _AuthMode.signUp && !_acceptedTerms) {
      setState(
        () => _error = context.tr(
          'Accept the terms and community rules to create an account.',
        ),
      );
      return;
    }
    final repository = ref.read(authRepositoryProvider);
    if (repository == null) {
      setState(
        () => _error = context.tr(
          'Sign-in is unavailable. Add Supabase settings to enable accounts.',
        ),
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
              () => _error = context.tr(
                'This email is already registered. Sign in instead, or use "Forgot password?".',
              ),
            );
          } else if (mounted && response.session != null) {
            context.pop();
          } else if (mounted) {
            setState(
              () => _message = context.tr(
                'Check your email to confirm your account, then sign in.',
              ),
            );
          }
          break;
        case _AuthMode.reset:
          await repository.resetPassword(_email.text);
          if (mounted) {
            setState(
              () => _message = context.tr(
                'Password reset instructions were sent to your email.',
              ),
            );
          }
          break;
      }
    } catch (error) {
      if (mounted) setState(() => _error = friendlyError(context, error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                    const Text('SHOTBOOK', style: ShotbookText.wordmark),
                    const SizedBox(height: 44),
                    Text(
                      isReset
                          ? context.tr('Reset password')
                          : isSignUp
                          ? context.tr('Create your account')
                          : context.tr('Sign in'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isReset
                          ? context.tr('We will email you a secure reset link.')
                          : context.tr(
                              'Photo recipes, saves and the community feed.',
                            ),
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                    const SizedBox(height: 40),
                    if (isSignUp) ...[
                      SectionLabel(context.tr('Username')),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('auth-username'),
                        controller: _username,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(),
                        validator: (value) =>
                            value == null || value.trim().length < 3
                            ? context.tr('Use at least 3 characters.')
                            : null,
                      ),
                      const SizedBox(height: 20),
                      SectionLabel(context.tr('Display name (optional)')),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('auth-display-name'),
                        controller: _displayName,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(),
                      ),
                      const SizedBox(height: 14),
                    ],
                    SectionLabel(context.tr('Email')),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('auth-email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(hintText: 'name@mail.ru'),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? context.tr('Enter a valid email address.')
                          : null,
                    ),
                    if (!isReset) ...[
                      const SizedBox(height: 20),
                      SectionLabel(context.tr('Password')),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: const Key('auth-password'),
                        controller: _password,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(),
                        validator: (value) => value == null || value.length < 6
                            ? context.tr('Use at least 6 characters.')
                            : null,
                      ),
                    ],
                    if (isSignUp) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            key: const Key('auth-accept-terms'),
                            value: _acceptedTerms,
                            onChanged: (value) =>
                                setState(() => _acceptedTerms = value ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                children: [
                                  Text(context.tr('I accept the ')),
                                  _InlineLink(
                                    text: context.tr(
                                      'terms and community rules',
                                    ),
                                    onTap: () =>
                                        openLegalPage(context, 'terms.html'),
                                  ),
                                  Text(context.tr(' and the ')),
                                  _InlineLink(
                                    text: context.tr('privacy policy'),
                                    onTap: () =>
                                        openLegalPage(context, 'privacy.html'),
                                  ),
                                  Text(context.tr('. I am 13 or older.')),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                    if (!isReset && !isSignUp)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const Key('auth-forgot'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => setState(() {
                            _mode = _AuthMode.reset;
                            _error = null;
                            _message = null;
                          }),
                          child: Text(context.tr('Forgot password?')),
                        ),
                      ),
                    const SizedBox(height: 20),
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
                                  ? context.tr('Send reset link')
                                  : isSignUp
                                  ? context.tr('Create account')
                                  : context.tr('Sign in'),
                            ),
                    ),
                    const SizedBox(height: 12),
                    // Sign in ⇄ create account ⇄ back from reset.
                    OutlinedButton(
                      key: const Key('auth-switch-mode'),
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
                            ? context.tr('Back to sign in')
                            : isSignUp
                            ? context.tr('Already have an account? Sign in')
                            : context.tr('Create account'),
                      ),
                    ),
                    if (!ref.watch(supabaseReadyProvider))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          context.tr(
                            'Browsing works in demo mode. Configure Supabase to use accounts.',
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: ShotbookColors.secondary),
                        ),
                      ),
                    const SizedBox(height: 40),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('Language'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: ShotbookColors.secondary,
                              ),
                            ),
                          ),
                          const LanguageSwitch(),
                        ],
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

class _InlineLink extends StatelessWidget {
  const _InlineLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(
      text,
      style: const TextStyle(decoration: TextDecoration.underline),
    ),
  );
}

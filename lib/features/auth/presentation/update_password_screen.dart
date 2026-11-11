import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../l10n/tr.dart';
import '../../../shared/services/supabase_providers.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() =>
      _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_password.text.length < 6) {
      setState(() => _error = context.tr('Use at least 6 characters.'));
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = context.tr('The passwords do not match.'));
      return;
    }
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      setState(
        () => _error = context.tr(
          'The recovery session is no longer available. Request a new link.',
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await client.auth.updateUser(UserAttributes(password: _password.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Password updated.'))),
        );
        context.go('/profile');
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = context.tr(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Choose a new password'))),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _password,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('New password'),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('Confirm password'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(
                  _busy ? context.tr('Saving…') : context.tr('Update password'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

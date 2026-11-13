import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/language_picker.dart';
import '../../../l10n/tr.dart';
import '../../../shared/services/legal_links.dart';
import '../../auth/application/auth_providers.dart';
import '../../safety/application/safety_providers.dart';
import '../../safety/presentation/safety_actions.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const LanguageSettingsTile(),
          if (user != null) ...[
            _Header(context.tr('Account')),
            _Tile(
              key: const Key('blocked-users'),
              icon: Icons.block,
              title: context.tr('Blocked users'),
              onTap: () => context.push('/settings/blocked'),
            ),
            _Tile(
              key: const Key('settings-sign-out'),
              icon: Icons.logout,
              title: context.tr('Sign out'),
              onTap: () async {
                await ref.read(authRepositoryProvider)?.signOut();
                ref.invalidate(authStateProvider);
                if (context.mounted) context.pop();
              },
            ),
            _Tile(
              key: const Key('delete-account'),
              icon: Icons.delete_forever_outlined,
              title: context.tr('Delete account'),
              danger: true,
              onTap: () => _deleteAccount(context, ref),
            ),
          ],
          _Header(context.tr('About')),
          _Tile(
            key: const Key('open-terms'),
            icon: Icons.gavel_outlined,
            title: context.tr('Terms and community rules'),
            onTap: () => openLegalPage(context, 'terms.html'),
          ),
          _Tile(
            key: const Key('open-privacy'),
            icon: Icons.privacy_tip_outlined,
            title: context.tr('Privacy policy'),
            onTap: () => openLegalPage(context, 'privacy.html'),
          ),
          _Tile(
            icon: Icons.photo_library_outlined,
            title: context.tr('Photo credits'),
            subtitle: context.tr(
              'Catalog photos are from Flickr under Creative Commons licences. The author and licence are shown on each photo.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final doneText = context.tr('Your account was deleted.');
    final failText = context.tr(
      'The account could not be deleted. Check your connection and try again.',
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await ref.read(safetyRepositoryProvider)!.deleteAccount();
      ref.invalidate(authStateProvider);
      refreshAfterSafetyChange(ref);
      router.pop(); // progress
      router.go('/profile');
      messenger.showSnackBar(SnackBar(content: Text(doneText)));
    } catch (_) {
      router.pop();
      messenger.showSnackBar(SnackBar(content: Text(failText)));
    }
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final word = context.tr('DELETE');
    final ready = _confirm.text.trim().toUpperCase() == word;
    return AlertDialog(
      title: Text(context.tr('Delete account?')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              'Your profile, posts, saved photos and reports are deleted for good. This cannot be undone.',
            ),
          ),
          const SizedBox(height: 14),
          Text(context.tr('Type {word} to confirm.', {'word': word})),
          const SizedBox(height: 8),
          TextField(
            key: const Key('delete-confirm-field'),
            controller: _confirm,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('delete-confirm'),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          child: Text(context.tr('Delete')),
        ),
      ],
    );
  }
}

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = ref.watch(blockedUsersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Blocked users'))),
      body: blocked.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(blockedUsersProvider),
            child: Text(context.tr('Try again')),
          ),
        ),
        data: (users) => users.isEmpty
            ? Center(
                child: Text(
                  context.tr('You have not blocked anyone.'),
                  style: const TextStyle(color: ShotbookColors.secondary),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(user.displayName),
                    subtitle: Text('@${user.username}'),
                    trailing: OutlinedButton(
                      key: Key('unblock-${user.id}'),
                      onPressed: () async {
                        await ref
                            .read(safetyRepositoryProvider)
                            ?.unblock(user.id);
                        refreshAfterSafetyChange(ref);
                      },
                      child: Text(context.tr('Unblock')),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: ShotbookColors.secondary),
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.danger = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: ShotbookColors.secondary),
            ),
      trailing: onTap == null
          ? null
          : const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: onTap,
    );
  }
}

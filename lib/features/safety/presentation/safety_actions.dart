import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../auth/application/auth_providers.dart';
import '../../discover/application/discover_providers.dart';
import '../../feed/application/feed_providers.dart';
import '../application/safety_providers.dart';
import '../data/safety_repository.dart';

const _reasonLabels = {
  'spam': 'Spam or scam',
  'nudity': 'Nudity or sexual content',
  'violence': 'Violence or dangerous acts',
  'harassment': 'Harassment or bullying',
  'hate': 'Hate speech',
  'copyright': 'Someone else\'s photo (copyright)',
  'other': 'Something else',
};

bool _requireSignIn(BuildContext context, WidgetRef ref) {
  if (ref.read(currentUserProvider) != null &&
      ref.read(safetyRepositoryProvider) != null) {
    return true;
  }
  context.push('/auth');
  return false;
}

void _snack(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// Report a photo (photoId) or a user (userId). Opens sign-in if needed.
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  String? photoId,
  String? userId,
}) async {
  if (!_requireSignIn(context, ref)) return;
  final sent = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => _ReportSheet(photoId: photoId, userId: userId),
  );
  if (sent == true && context.mounted) {
    _snack(context, context.tr('Thanks. We review reports within 24 hours.'));
  }
}

/// Block a user after confirmation; their posts disappear right away.
Future<bool> confirmAndBlock(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
  required String name,
}) async {
  if (!_requireSignIn(context, ref)) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr('Block {name}?', {'name': name})),
      content: Text(
        context.tr(
          'You will no longer see their photos. They are not notified. You can unblock them in Settings.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('confirm-block'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(context.tr('Block')),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  try {
    await ref.read(safetyRepositoryProvider)!.block(userId);
    refreshAfterSafetyChange(ref);
    if (context.mounted) _snack(context, context.tr('User blocked.'));
    return true;
  } catch (_) {
    if (context.mounted) {
      _snack(context, context.tr('Something went wrong. Try again.'));
    }
    return false;
  }
}

/// Lists that depend on blocks and moderation reload after a change.
void refreshAfterSafetyChange(WidgetRef ref) {
  ref.invalidate(feedPostsProvider);
  ref.invalidate(photoCatalogSourceProvider);
  ref.invalidate(blockedUsersProvider);
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({this.photoId, this.userId});

  final String? photoId;
  final String? userId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  String? _reason;
  final _details = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_reason == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(safetyRepositoryProvider)!
          .report(
            photoId: widget.photoId,
            userId: widget.userId,
            reason: _reason!,
            details: _details.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AlreadyReportedException {
      if (mounted) {
        setState(() => _error = context.tr('You have already reported this.'));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr('Something went wrong. Try again.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.photoId != null
                    ? context.tr('Report photo')
                    : context.tr('Report user'),
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'What is wrong? The author will not see who reported.',
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: ShotbookColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (value) => setState(() => _reason = value),
                child: Column(
                  children: [
                    for (final reason in reportReasons)
                      RadioListTile<String>(
                        key: Key('report-reason-$reason'),
                        contentPadding: EdgeInsets.zero,
                        value: reason,
                        title: Text(context.tr(_reasonLabels[reason]!)),
                      ),
                  ],
                ),
              ),
              TextField(
                key: const Key('report-details'),
                controller: _details,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: context.tr('Details (optional)'),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              FilledButton(
                key: const Key('report-send'),
                onPressed: _reason == null || _busy ? null : _send,
                child: Text(context.tr('Send report')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

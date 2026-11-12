import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/discover/domain/photo_reference.dart';
import '../../features/saved/application/saved_photo_provider.dart';
import '../../l10n/tr.dart';

/// An extra action shown in the long-press menu, e.g. "Delete post".
class PhotoSheetAction {
  const PhotoSheetAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final Key? key;
}

/// Cards are clean photos. Everything a card can do lives here and opens
/// on a long press.
Future<void> showPhotoActions(
  BuildContext context, {
  required PhotoReference photo,
  String? author,
  List<PhotoSheetAction> extraActions = const [],
}) {
  HapticFeedback.mediumImpact();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetContext) => _PhotoActionsSheet(
      photo: photo,
      author: author,
      extraActions: extraActions,
      // Navigation from the sheet uses the page's context, which outlives it.
      hostContext: context,
    ),
  );
}

class _PhotoActionsSheet extends ConsumerWidget {
  const _PhotoActionsSheet({
    required this.photo,
    required this.author,
    required this.extraActions,
    required this.hostContext,
  });

  final PhotoReference photo;
  final String? author;
  final List<PhotoSheetAction> extraActions;
  final BuildContext hostContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds =
        ref.watch(savedPhotoIdsProvider).asData?.value ?? const <String>{};
    final isSaved =
        savedIds.contains(photo.id) ||
        (photo.remoteId != null && savedIds.contains(photo.remoteId));
    final textTheme = Theme.of(context).textTheme;

    void go(String location) {
      Navigator.of(context).pop();
      hostContext.push(location);
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              photo.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              [
                ?author,
                context.tr(photo.category),
                context.tr('Views: {n}', {'n': '${photo.viewCount}'}),
              ].join(' · '),
              key: const Key('sheet-meta'),
              style: textTheme.bodySmall?.copyWith(
                color: ShotbookColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            ListTile(
              key: const Key('sheet-open'),
              leading: const Icon(Icons.open_in_full),
              title: Text(context.tr('Open')),
              onTap: () => go('/photos/${photo.id}'),
            ),
            ListTile(
              key: const Key('sheet-save'),
              leading: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              title: Text(
                isSaved
                    ? context.tr('Remove saved frame')
                    : context.tr('Save frame'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                ref
                    .read(savedPhotoIdsProvider.notifier)
                    .toggle(photo.remoteId ?? photo.id);
              },
            ),
            ListTile(
              key: const Key('sheet-repeat'),
              leading: const Icon(Icons.filter_center_focus),
              title: Text(context.tr('Repeat this shot')),
              subtitle: Text(
                context.tr('Camera with this photo as a see-through guide'),
              ),
              onTap: () => go('/photos/${photo.id}/repeat'),
            ),
            for (final action in extraActions)
              ListTile(
                key: action.key,
                leading: Icon(action.icon),
                title: Text(action.label),
                onTap: () {
                  Navigator.of(context).pop();
                  action.onSelected();
                },
              ),
          ],
        ),
      ),
    );
  }
}

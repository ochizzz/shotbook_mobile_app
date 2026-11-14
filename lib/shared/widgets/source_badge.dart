import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../features/discover/domain/photo_reference.dart';
import '../../l10n/tr.dart';

extension PhotoSource on PhotoReference {
  /// Curated reference from the SHOTBOOK library (may be shot on a pro
  /// camera), as opposed to a post by a community member.
  bool get isLibrary => sourceType == 'curated';
}

/// Small mark that tells library references from members' posts.
/// [compact] is the icon-only version for photo grids.
class SourceBadge extends StatelessWidget {
  const SourceBadge({required this.photo, this.compact = false, super.key});

  final PhotoReference photo;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final library = photo.isLibrary;
    final icon = library ? Icons.auto_stories_outlined : Icons.person_outline;
    final label = library
        ? context.tr('SHOTBOOK library')
        : context.tr('Member post');
    if (compact) {
      return Semantics(
        label: label,
        child: Container(
          key: Key(library ? 'badge-library' : 'badge-member'),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: ShotbookColors.background.withValues(alpha: 0.62),
            borderRadius: shotbookBorderRadius,
          ),
          child: Icon(icon, size: 13, color: ShotbookColors.primary),
        ),
      );
    }
    return Container(
      key: Key(library ? 'badge-library-full' : 'badge-member-full'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: ShotbookColors.border),
        borderRadius: shotbookBorderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ShotbookColors.secondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: ShotbookColors.secondary),
          ),
        ],
      ),
    );
  }
}

/// One line under the badge explaining what the source means.
String sourceExplanation(BuildContext context, PhotoReference photo) =>
    photo.isLibrary
    ? context.tr(
        'A reference from the SHOTBOOK library. It may have been shot on a professional camera; the settings show how to get close on a phone.',
      )
    : context.tr('Shot and shared by a SHOTBOOK member.');

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/photo_actions_sheet.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../../features/discover/domain/photo_reference.dart';

/// A clean photo block: no text, no buttons. Tap opens the photo, a long
/// press opens its actions.
class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    required this.photo,
    this.extraActions = const [],
    super.key,
  });

  final PhotoReference photo;
  final List<PhotoSheetAction> extraActions;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: shotbookBorderRadius,
      child: AspectRatio(
        aspectRatio: photo.imageAspectRatio,
        child: Material(
          color: ShotbookColors.card,
          child: InkWell(
            key: ValueKey('photo-${photo.id}'),
            onTap: () => context.push('/photos/${photo.id}'),
            onLongPress: () => showPhotoActions(
              context,
              photo: photo,
              extraActions: extraActions,
            ),
            child: Semantics(
              label: photo.title,
              child: PhotoReferenceImage(photo: photo),
            ),
          ),
        ),
      ),
    );
  }
}

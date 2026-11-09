import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/photo_reference_image.dart';
import '../../../features/discover/domain/photo_reference.dart';

class PhotoGridTile extends StatelessWidget {
  const PhotoGridTile({
    required this.photo,
    required this.isSaved,
    required this.onSave,
    super.key,
  });

  final PhotoReference photo;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AspectRatio(
            aspectRatio: photo.imageAspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Material(
                  color: ShotbookColors.card,
                  child: InkWell(
                    key: ValueKey('photo-${photo.id}'),
                    onTap: () => context.push('/photos/${photo.id}'),
                    child: PhotoReferenceImage(photo: photo),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: ShotbookColors.background.withValues(alpha: 0.72),
                    shape: const CircleBorder(),
                    child: IconButton(
                      key: ValueKey('save-card-${photo.id}'),
                      tooltip: isSaved ? 'Remove saved frame' : 'Save frame',
                      visualDensity: VisualDensity.compact,
                      onPressed: onSave,
                      icon: Icon(
                        isSaved ? Icons.bookmark : Icons.bookmark_border,
                        size: 19,
                        color: ShotbookColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          photo.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          photo.category,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: ShotbookColors.secondary),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

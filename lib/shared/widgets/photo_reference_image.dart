import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/tr.dart';
import '../../features/discover/domain/photo_reference.dart';

class PhotoReferenceImage extends StatelessWidget {
  const PhotoReferenceImage({
    required this.photo,
    this.fit = BoxFit.cover,
    super.key,
  });

  final PhotoReference photo;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: photo.imageUrl,
      fit: fit,
      placeholder: (context, url) => const _ImagePlaceholder(),
      errorWidget: (context, url, error) => _ImageFallback(photo: photo),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ShotbookColors.card,
      child: Center(
        child: Icon(
          Icons.photo_outlined,
          color: ShotbookColors.secondary,
          size: 26,
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.photo});

  final PhotoReference photo;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ShotbookColors.card,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_outlined,
                color: ShotbookColors.secondary,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(photo.category),
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: ShotbookColors.secondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

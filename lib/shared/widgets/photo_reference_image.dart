import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../l10n/tr.dart';
import '../../features/discover/domain/photo_reference.dart';

class PhotoReferenceImage extends StatelessWidget {
  const PhotoReferenceImage({
    required this.photo,
    this.fit = BoxFit.cover,
    this.thumbnail = false,
    super.key,
  });

  final PhotoReference photo;
  final BoxFit fit;

  /// Grids load the small version of the photo.
  final bool thumbnail;

  @override
  Widget build(BuildContext context) {
    final url = thumbnail ? photo.gridImageUrl : photo.imageUrl;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Decode at the size it is shown, not the full file size: keeps
        // memory low and scrolling smooth on long grids.
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final width = constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round()
            : null;
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          memCacheWidth: width,
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (context, url) => const _ImagePlaceholder(),
          errorWidget: (context, url, error) =>
              thumbnail && url != photo.imageUrl
              // A missing thumbnail falls back to the full image.
              ? PhotoReferenceImage(photo: photo, fit: fit)
              : _ImageFallback(photo: photo),
        );
      },
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

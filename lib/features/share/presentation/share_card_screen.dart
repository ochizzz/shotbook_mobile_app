import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../../shared/services/friendly_error.dart';
import '../../../shared/services/supabase_providers.dart';
import '../../../shared/services/unsplash_tracking.dart';
import '../../../shared/widgets/graphite/graphite.dart';
import '../../discover/application/discover_providers.dart';
import '../../discover/data/seed_photo_references.dart';
import '../../discover/domain/photo_reference.dart';
import '../domain/shooting_summary.dart';

/// Logical width the card is laid out at (Penpot "7 · Share card"). It is
/// scaled to fit the screen and rendered at 3× (1080 px wide) for sharing.
const shareCardWidth = 360.0;

const _fileName = 'shotbook-recipe.png';

/// Preview of the recipe card and a button that shares it as a PNG.
class ShareCardScreen extends ConsumerStatefulWidget {
  const ShareCardScreen({required this.photoId, super.key});

  final String photoId;

  @override
  ConsumerState<ShareCardScreen> createState() => _ShareCardScreenState();
}

class _ShareCardScreenState extends ConsumerState<ShareCardScreen> {
  final _cardKey = GlobalKey();
  final _buttonKey = GlobalKey();
  bool _sharing = false;

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/photos/${widget.photoId}');
    }
  }

  Future<Uint8List> _renderCard() async {
    final boundary = _cardKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('The share card is not on screen.');
    }
    final image = await boundary.toImage(pixelRatio: 3);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('The share card could not be drawn.');
      return data.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _share(PhotoReference photo) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final text = context.tr('Recipe from SHOTBOOK');
    // iPad anchors the share sheet to the button.
    final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    try {
      final bytes = await _renderCard();
      trackUnsplashUse(ref.read(supabaseClientProvider), photo);
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [
            XFile.fromData(bytes, mimeType: 'image/png', name: _fileName),
          ],
          fileNameOverrides: const [_fileName],
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyError(context, error))));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(remotePhotoCatalogProvider);
    final appBar = AppBar(
      leading: IconButton(
        key: const Key('share-close'),
        tooltip: context.tr('Close'),
        onPressed: _close,
        icon: const Icon(Icons.close),
      ),
      title: Text(context.tr('Share recipe')),
    );
    if (catalogState.isLoading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final catalog = catalogState.asData?.value ?? seedPhotoReferences;
    final matches = catalog.where((photo) => photo.id == widget.photoId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: appBar,
        body: Center(
          child: Text(context.tr('This photo is not in the catalog.')),
        ),
      );
    }
    final photo = matches.first;

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    // The border and rounding are for the preview only; the
                    // PNG is the square card inside.
                    child: Container(
                      foregroundDecoration: BoxDecoration(
                        borderRadius: shotbookCardRadius,
                        border: Border.all(color: ShotbookColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: shotbookCardRadius,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          child: SizedBox(
                            width: shareCardWidth,
                            child: RepaintBoundary(
                              key: _cardKey,
                              child: RecipeShareCard(photo: photo),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: FilledButton.icon(
                key: _buttonKey,
                onPressed: _sharing ? null : () => _share(photo),
                icon: _sharing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ShotbookColors.tertiary,
                        ),
                      )
                    : const Icon(Icons.share_outlined, size: 20),
                label: Text(context.tr('Share')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card itself, laid out at [shareCardWidth]: photo with viewfinder
/// ticks, "СНЯТО ПО РЕЦЕПТУ", title, mono shooting lines and the SHOTBOOK
/// footer.
class RecipeShareCard extends StatelessWidget {
  const RecipeShareCard({required this.photo, super.key});

  final PhotoReference photo;

  @override
  Widget build(BuildContext context) {
    final preset = presetOf(photo);
    final lines = [
      deviceSummary(photo),
      shootingSummary(photo, focal: false),
      if (preset != null) context.tr('Preset: {name}', {'name': preset}),
    ].whereType<String>().toList();
    const lineStyle = TextStyle(
      fontFamily: shotbookMonoFont,
      fontSize: 12,
      letterSpacing: 0.3,
      height: 1.2,
      color: ShotbookColors.secondary,
    );

    return ColoredBox(
      color: ShotbookColors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 420,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _CardPhoto(photo: photo),
                const ViewfinderTicks(inset: 16, length: 14, opacity: 0.6),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Shot from a recipe').toUpperCase(),
                  style: ShotbookText.kicker.copyWith(height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  photo.title,
                  key: const Key('share-card-title'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: shotbookTitleFont,
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    letterSpacing: -0.2,
                    height: 1.2,
                    color: ShotbookColors.primary,
                  ),
                ),
                SizedBox(height: lines.isEmpty ? 20 : 40),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      line,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: lineStyle,
                    ),
                  ),
              ],
            ),
          ),
          const ColoredBox(
            color: ShotbookColors.border,
            child: SizedBox(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 5, 20, 19),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHOTBOOK',
                          style: ShotbookText.wordmark.copyWith(
                            fontSize: 12,
                            letterSpacing: 1.2,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          context.tr('Recipe in SHOTBOOK'),
                          style: const TextStyle(
                            fontFamily: shotbookBodyFont,
                            fontSize: 12,
                            height: 1.2,
                            color: ShotbookColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: ShotbookColors.border),
                  ),
                  child: Text(
                    'QR',
                    style: ShotbookText.data.copyWith(
                      fontSize: 10,
                      color: ShotbookColors.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full image, the thumbnail if that fails, else the flat placeholder.
/// No fade-in, so a share mid-load never captures a half-faded photo.
class _CardPhoto extends StatelessWidget {
  const _CardPhoto({required this.photo});

  final PhotoReference photo;

  static const _placeholder = ColoredBox(color: ShotbookColors.placeholder);

  Widget _image(String url, Widget Function() onError) => CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    memCacheWidth: (shareCardWidth * 3).round(),
    fadeInDuration: Duration.zero,
    fadeOutDuration: Duration.zero,
    placeholder: (context, url) => _placeholder,
    errorWidget: (context, url, error) => onError(),
  );

  @override
  Widget build(BuildContext context) {
    final thumb = photo.thumbUrl;
    final hasThumb =
        thumb != null && thumb.isNotEmpty && thumb != photo.imageUrl;
    return _image(
      photo.imageUrl,
      () => hasThumb ? _image(thumb, () => _placeholder) : _placeholder,
    );
  }
}

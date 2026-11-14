import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../features/discover/domain/photo_reference.dart';
import '../../l10n/tr.dart';
import '../services/unsplash_tracking.dart';

/// Credit line with links to the photographer, the licence and the source.
/// For Unsplash photos: "Photo by `Name` on Unsplash", both linked with
/// referral parameters, as the Unsplash API guidelines require.
class PhotoCredit extends StatefulWidget {
  const PhotoCredit({required this.photo, super.key});

  final PhotoReference photo;

  @override
  State<PhotoCredit> createState() => _PhotoCreditState();
}

class _PhotoCreditState extends State<PhotoCredit> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  TextSpan _link(String text, String? url) {
    if (url == null || url.isEmpty) return TextSpan(text: text);
    final recognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ).catchError((Object _) => false);
    _recognizers.add(recognizer);
    return TextSpan(
      text: text,
      style: const TextStyle(
        decoration: TextDecoration.underline,
        color: ShotbookColors.primary,
      ),
      recognizer: recognizer,
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    final photo = widget.photo;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: ShotbookColors.secondary);

    final List<InlineSpan> spans;
    if (photo.isUnsplash) {
      spans = [
        TextSpan(text: context.tr('Photo by ')),
        _link(photo.credit, withUnsplashReferral(photo.creatorUrl ?? '')),
        TextSpan(text: context.tr(' on ')),
        _link('Unsplash', withUnsplashReferral('https://unsplash.com/')),
      ];
    } else {
      final source =
          Uri.tryParse(photo.sourcePage)?.host.contains('flickr') ?? false
          ? 'Flickr'
          : context.tr('source');
      spans = [
        TextSpan(text: context.tr('Photo by ')),
        _link(photo.credit, photo.creatorUrl),
        const TextSpan(text: ' · '),
        _link(photo.license, photo.licenseUrl),
        const TextSpan(text: ' · '),
        _link(source, photo.sourcePage),
      ];
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      key: const Key('photo-credit'),
    );
  }
}

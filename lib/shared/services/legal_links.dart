import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/tr.dart';

/// Public site with the privacy policy, terms and account deletion page.
/// Override at build time with --dart-define=LEGAL_SITE_URL=https://…
const legalSiteUrl = String.fromEnvironment(
  'LEGAL_SITE_URL',
  defaultValue: 'https://ochizzz.github.io/shotbook_mobile_app',
);

String legalPageUrl(String page) => '$legalSiteUrl/$page';

Future<void> openLegalPage(BuildContext context, String page) async {
  final opened = await launchUrl(
    Uri.parse(legalPageUrl(page)),
    mode: LaunchMode.externalApplication,
  ).catchError((Object _) => false);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Could not open the page.'))),
    );
  }
}

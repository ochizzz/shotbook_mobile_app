import 'package:flutter/material.dart';

import '../../../l10n/tr.dart';
import '../../../shared/widgets/graphite/graphite.dart';

/// Graphite section of a recipe: a mono caps label ("ПОЗА") over 44 px
/// label/value rows with a 1 px rule under each.
class MetadataSection extends StatelessWidget {
  const MetadataSection({
    required this.title,
    required this.values,
    this.monoKeys = const {},
    super.key,
  });

  /// English section name, translated here.
  final String title;
  final Map<String, String> values;

  /// Keys whose numeric values are shooting data and read better
  /// monospaced (ISO, shutter, aperture…).
  final Set<String> monoKeys;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(context.tr(title)),
          const SizedBox(height: 8),
          for (final entry in values.entries)
            MetaRow(
              label: context.tr(entry.key),
              value: entry.value,
              mono: _isNumeric(entry.key, entry.value),
            ),
        ],
      ),
    );
  }

  bool _isNumeric(String key, String value) =>
      monoKeys.contains(key) &&
      RegExp(r'^(f/?)?[≈~+\-−±]?\s*\d', caseSensitive: false).hasMatch(value);
}

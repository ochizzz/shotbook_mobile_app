import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';

class DiscoverEmptyState extends StatelessWidget {
  const DiscoverEmptyState({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        children: [
          const Icon(
            Icons.search_off,
            color: ShotbookColors.secondary,
            size: 28,
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('No frames match these filters.'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('Try another search or clear your filters.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: ShotbookColors.secondary),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onClear,
            child: Text(context.tr('Clear filters')),
          ),
        ],
      ),
    );
  }
}

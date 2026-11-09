import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class MetadataSection extends StatelessWidget {
  const MetadataSection({required this.title, required this.values, super.key});

  final String title;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: ShotbookColors.secondary),
          ),
          const SizedBox(height: 10),
          ...values.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: ShotbookColors.secondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Text(entry.value, textAlign: TextAlign.end),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 18),
        ],
      ),
    );
  }
}

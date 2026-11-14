import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../camera/domain/camera_device.dart';
import '../application/discover_providers.dart';

/// A small dropdown under the categories: filter recipes by phone.
class PhoneFilter extends ConsumerWidget {
  const PhoneFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(discoverFiltersProvider).deviceId;
    final device = selectedId == null
        ? null
        : cameraDevices.where((d) => d.id == selectedId).firstOrNull;
    final style = Theme.of(context).textTheme.labelMedium;
    return Row(
      children: [
        InkWell(
          key: const Key('phone-filter'),
          borderRadius: shotbookBorderRadius,
          onTap: () => _open(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smartphone,
                  size: 15,
                  color: device == null
                      ? ShotbookColors.secondary
                      : ShotbookColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  device == null
                      ? context.tr('All phones')
                      : '${context.tr(device.brand)} ${context.tr(device.model)}',
                  style: style?.copyWith(
                    color: device == null
                        ? ShotbookColors.secondary
                        : ShotbookColors.primary,
                  ),
                ),
                const Icon(
                  Icons.expand_more,
                  size: 16,
                  color: ShotbookColors.secondary,
                ),
              ],
            ),
          ),
        ),
        if (device != null) ...[
          const SizedBox(width: 4),
          TextButton(
            key: const Key('phone-filter-guide'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: style,
            ),
            onPressed: () => context.push('/camera/${device.id}'),
            child: Text(context.tr('Camera guide')),
          ),
          IconButton(
            key: const Key('phone-filter-clear'),
            tooltip: context.tr('All phones'),
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            onPressed: () =>
                ref.read(discoverFiltersProvider.notifier).setDevice(null),
            icon: const Icon(Icons.close, color: ShotbookColors.secondary),
          ),
        ],
      ],
    );
  }

  void _open(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      builder: (context) => const _PhoneSheet(),
    );
  }
}

class _PhoneSheet extends ConsumerStatefulWidget {
  const _PhoneSheet();

  @override
  ConsumerState<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends ConsumerState<_PhoneSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(discoverFiltersProvider).deviceId;
    final catalog = ref.watch(remotePhotoCatalogProvider).asData?.value;
    final counts = <String, int>{};
    for (final photo in catalog ?? const []) {
      final id = photo.deviceId;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    final q = _query.trim().toLowerCase();
    final devices = cameraDevices
        .where(
          (d) =>
              q.isEmpty ||
              '${d.brand} ${d.model} ${d.year}'.toLowerCase().contains(q),
        )
        .toList();
    final rows = <Widget>[];
    String? brand;
    for (final d in devices) {
      if (d.brand != brand) {
        brand = d.brand;
        rows.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text(
              context.tr(d.brand).toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.2,
                color: ShotbookColors.secondary,
              ),
            ),
          ),
        );
      }
      rows.add(
        _row(
          context,
          key: Key('phone-option-${d.id}'),
          title: context.tr(d.model),
          trailing: counts[d.id] == null ? null : '${counts[d.id]}',
          selected: d.id == selectedId,
          onTap: () => _select(d.id),
        ),
      );
    }
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              key: const Key('phone-search'),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: context.tr('Search a phone model'),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _row(
                  context,
                  key: const Key('phone-option-all'),
                  title: context.tr('All phones'),
                  selected: selectedId == null,
                  onTap: () => _select(null),
                ),
                ...rows,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    context.tr(
                      'The number is how many recipes are written for that phone.',
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: ShotbookColors.secondary,
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

  void _select(String? id) {
    HapticFeedback.selectionClick();
    ref.read(discoverFiltersProvider.notifier).setDevice(id);
    Navigator.of(context).pop();
  }

  Widget _row(
    BuildContext context, {
    required Key key,
    required String title,
    required bool selected,
    required VoidCallback onTap,
    String? trailing,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: selected
                      ? ShotbookColors.primary
                      : ShotbookColors.primary.withValues(alpha: 0.85),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: const TextStyle(
                  fontSize: 12,
                  color: ShotbookColors.secondary,
                ),
              ),
            if (selected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

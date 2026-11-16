import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../l10n/tr.dart';
import '../../camera/domain/camera_device.dart';
import '../../recipe/my_phone.dart';
import '../../recipe/phone_profile.dart';

/// A small dropdown under the categories: the phone every recipe is
/// worked out for ("My phone").
class PhoneFilter extends ConsumerWidget {
  const PhoneFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(myPhoneProvider);
    final device = selectedId == fallbackPhoneId
        ? null
        : cameraDevices.where((d) => d.id == selectedId).firstOrNull;
    final style = Theme.of(context).textTheme.labelMedium;
    return Row(
      children: [
        Flexible(
          child: InkWell(
            key: const Key('phone-filter'),
            borderRadius: shotbookBorderRadius,
            onTap: () => _open(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.smartphone,
                    size: 15,
                    color: ShotbookColors.accent,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${context.tr('My phone')}: ',
                    style: style?.copyWith(color: ShotbookColors.secondary),
                  ),
                  Flexible(
                    child: Text(
                      device == null
                          ? context.tr('Choose')
                          : context.tr(device.model),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style?.copyWith(color: ShotbookColors.primary),
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
        ),
        if (device != null) ...[
          const SizedBox(width: 4),
          IconButton(
            key: const Key('phone-filter-guide'),
            tooltip: context.tr('Camera guide'),
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            onPressed: () => context.push('/camera/${device.id}'),
            icon: const Icon(
              Icons.menu_book_outlined,
              color: ShotbookColors.secondary,
            ),
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
    final selectedId = ref.watch(myPhoneProvider);
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
                ...rows,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Text(
                    context.tr(
                      'Every recipe is worked out for the chosen phone from the original shot: lens, ISO and shutter.',
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

  void _select(String id) {
    HapticFeedback.selectionClick();
    ref.read(myPhoneProvider.notifier).select(id);
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

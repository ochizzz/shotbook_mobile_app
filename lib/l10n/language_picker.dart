import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import 'language_provider.dart';
import 'tr.dart';

const _languageNames = {'ru': 'Русский', 'en': 'English'};

/// Settings row that shows the current interface language and opens a sheet
/// to change it. Put it anywhere in settings; it works signed in or out.
class LanguageSettingsTile extends ConsumerWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(languageProvider);
    return ListTile(
      key: const Key('language-setting'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.language),
      title: Text(context.tr('Interface language')),
      subtitle: Text(_languageNames[code] ?? code),
      trailing: const Icon(Icons.arrow_forward_ios, size: 15),
      onTap: () => showLanguageSheet(context, ref),
    );
  }
}

Future<void> showLanguageSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: ShotbookColors.surface,
    builder: (sheetContext) => SafeArea(
      child: Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(languageProvider);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    context.tr('Interface language'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              for (final code in supportedLanguageCodes)
                ListTile(
                  key: Key('language-$code'),
                  title: Text(_languageNames[code]!),
                  trailing: code == current ? const Icon(Icons.check) : null,
                  onTap: () async {
                    await ref.read(languageProvider.notifier).select(code);
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    ),
  );
}

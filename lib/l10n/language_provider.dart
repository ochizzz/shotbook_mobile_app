import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const languagePreferenceKey = 'shotbook.language';
const supportedLanguageCodes = ['ru', 'en'];
const defaultLanguageCode = 'ru';

/// Language chosen on a previous run. `main` overrides it from storage;
/// Russian is the default for new installs.
final initialLanguageProvider = Provider<String>((ref) => defaultLanguageCode);

class LanguageNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(initialLanguageProvider);

  Future<void> select(String code) async {
    if (!supportedLanguageCodes.contains(code) || code == state) return;
    state = code;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(languagePreferenceKey, code);
    } catch (_) {
      // The choice still applies for this run if storage is unavailable.
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(
  LanguageNotifier.new,
);

final localeProvider = Provider<Locale>(
  (ref) => Locale(ref.watch(languageProvider)),
);

Future<String> loadSavedLanguage() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(languagePreferenceKey);
    if (code != null && supportedLanguageCodes.contains(code)) return code;
  } catch (_) {
    // Fall back to the default language.
  }
  return defaultLanguageCode;
}

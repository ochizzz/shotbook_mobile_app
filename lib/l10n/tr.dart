import 'package:flutter/widgets.dart';

import 'ru_strings.dart';

/// Lightweight UI translation. The English text is the key; Russian comes
/// from [ruStrings]. Placeholders look like `{name}` and are filled from
/// [args]. Unknown languages and missing keys fall back to English.
///
/// Reading the locale through [Localizations] makes widgets rebuild when the
/// user changes the language.
extension ShotbookTr on BuildContext {
  String tr(String en, [Map<String, String> args = const {}]) {
    var text = isRussian ? (ruStrings[en] ?? en) : en;
    args.forEach((key, value) => text = text.replaceAll('{$key}', value));
    return text;
  }

  bool get isRussian => Localizations.localeOf(this).languageCode == 'ru';
}

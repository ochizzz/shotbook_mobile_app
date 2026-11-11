import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/l10n/ru_strings.dart';

String _unescape(String raw) => raw
    .replaceAll(r"\'", "'")
    .replaceAll(r'\"', '"')
    .replaceAll(r'\n', '\n')
    .replaceAll(r'\$', r'$');

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  // Every literal passed to context.tr(...) must have a Russian translation
  // with the same {placeholders}.
  final literal = RegExp(
    r'''\btr\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''',
  );

  test('every tr() string has a Russian translation', () {
    final missing = <String>[];
    final broken = <String>[];
    var found = 0;
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();
      for (final match in literal.allMatches(source)) {
        found++;
        final key = _unescape(match.group(1) ?? match.group(2)!);
        final ru = ruStrings[key];
        if (ru == null) {
          missing.add('${file.path}: $key');
        } else if (!_placeholders(key).containsAll(_placeholders(ru)) ||
            !_placeholders(ru).containsAll(_placeholders(key))) {
          broken.add('${file.path}: $key');
        }
      }
    }
    expect(found, greaterThan(0));
    expect(
      missing,
      isEmpty,
      reason: 'Missing Russian strings:\n${missing.join('\n')}',
    );
    expect(
      broken,
      isEmpty,
      reason: 'Placeholder mismatch:\n${broken.join('\n')}',
    );
  });

  test('Russian dictionary has no empty or untranslated entries', () {
    for (final entry in ruStrings.entries) {
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
    }
  });
}

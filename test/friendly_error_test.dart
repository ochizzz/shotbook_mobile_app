import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/l10n/ru_strings.dart';
import 'package:shotbook/shared/services/friendly_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('wrong login shows a plain sentence, not the server log', () {
    const error = AuthApiException(
      'Invalid login credentials',
      statusCode: '400',
      code: 'invalid_credentials',
    );
    expect(friendlyErrorKey(error), 'Wrong email or password.');
    expect(ruStrings[friendlyErrorKey(error)], 'Неверный email или пароль.');
  });

  test('old servers without a code are still understood', () {
    const error = AuthException('Invalid login credentials', statusCode: '400');
    expect(friendlyErrorKey(error), 'Wrong email or password.');
  });

  test('network, rate limit and unknown errors map to friendly text', () {
    expect(
      friendlyErrorKey(const SocketException('Failed host lookup')),
      'No connection. Check the internet and try again.',
    );
    expect(
      friendlyErrorKey(const AuthException('x', statusCode: '429')),
      'Too many attempts. Wait a minute and try again.',
    );
    expect(
      friendlyErrorKey(Exception('PostgrestException(code: 500, details: …)')),
      'Something went wrong. Try again.',
    );
  });

  test('every friendly message has a Russian translation', () {
    final source = File('lib/shared/services/friendly_error.dart')
        .readAsStringSync();
    final keys = RegExp(r"return '((?:[^'\\]|\\.)*)';")
        .allMatches(source)
        .map((m) => m.group(1)!.replaceAll(r"\'", "'"));
    for (final key in keys) {
      expect(ruStrings.containsKey(key), isTrue, reason: key);
    }
  });
}

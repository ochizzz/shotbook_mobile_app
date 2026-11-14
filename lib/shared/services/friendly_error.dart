import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/tr.dart';

/// Turns any error into one short, translated sentence for the user.
/// Never shows raw exception text, status codes or server logs.
String friendlyError(BuildContext context, Object error) =>
    context.tr(friendlyErrorKey(error));

/// The English key (see ru_strings) for [error]; testable without a context.
String friendlyErrorKey(Object error) {
  // Our own validation messages are already written for people.
  if (error is FormatException) return error.message;

  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException ||
      error is AuthRetryableFetchException) {
    return 'No connection. Check the internet and try again.';
  }

  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'Wrong email or password.';
      case 'email_not_confirmed':
        return 'Confirm your email first: open the link in the letter we sent.';
      case 'user_already_exists':
      case 'email_exists':
        return 'This email is already registered. Sign in instead, or use "Forgot password?".';
      case 'weak_password':
        return 'The password is too weak. Use at least 6 characters, mixing letters and numbers.';
      case 'same_password':
        return 'The new password must differ from the old one.';
      case 'over_email_send_rate_limit':
        return 'Too many emails requested. Wait a minute, then use the newest email.';
      case 'over_request_rate_limit':
        return 'Too many attempts. Wait a minute and try again.';
      case 'email_address_invalid':
      case 'validation_failed':
        return 'Enter a valid email address.';
      case 'signup_disabled':
        return 'Sign-up is closed for now.';
      case 'user_banned':
        return 'This account is blocked for breaking the rules.';
      case 'session_expired':
      case 'session_not_found':
      case 'refresh_token_not_found':
        return 'Your session has ended. Sign in again.';
    }
    if (error.statusCode == '429') {
      return 'Too many attempts. Wait a minute and try again.';
    }
    // Older servers send the message without a code.
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Wrong email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Confirm your email first: open the link in the letter we sent.';
    }
    return 'Could not sign in. Try again.';
  }

  if (error is StorageException) {
    if (error.statusCode == '413') {
      return 'The image is too large. Choose a smaller one.';
    }
    return 'The image could not be uploaded. Try again.';
  }

  if (error is PostgrestException) {
    if (error.code == '42501') return 'You do not have permission to do this.';
    return 'Something went wrong. Try again.';
  }

  final text = error.toString();
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return 'No connection. Check the internet and try again.';
  }
  return 'Something went wrong. Try again.';
}

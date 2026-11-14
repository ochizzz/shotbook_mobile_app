import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/shared/services/unsplash_tracking.dart';

void main() {
  test('links back to Unsplash carry the referral parameters', () {
    expect(
      withUnsplashReferral('https://unsplash.com/@anniespratt'),
      'https://unsplash.com/@anniespratt?utm_source=shotbook&utm_medium=referral',
    );
    expect(
      withUnsplashReferral('https://unsplash.com/'),
      'https://unsplash.com/?utm_source=shotbook&utm_medium=referral',
    );
  });
}

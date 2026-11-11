import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/l10n/language_provider.dart';
import 'package:shotbook/features/discover/application/discover_providers.dart';
import 'package:shotbook/features/discover/domain/photo_reference.dart';
import 'package:shotbook/features/saved/application/saved_photo_provider.dart';
import 'package:shotbook/features/saved/data/saved_photo_repository.dart';

void main() {
  testWidgets('narrow Discover layout handles a long title and failed image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const longTitlePhoto = PhotoReference(
      id: 'long-title',
      title: 'A very long photographic reference title that must stay within its card',
      description: 'Layout check',
      imageUrl: 'https://example.invalid/missing.jpg',
      category: 'Portrait',
      sourcePage: 'https://example.invalid',
      credit: 'Demo',
      license: 'Public domain',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialLanguageProvider.overrideWithValue('en'),

          photoCatalogProvider.overrideWithValue([longTitlePhoto]),
          savedPhotoRepositoryProvider.overrideWithValue(
            SavedPhotoRepository(store: _MemorySavedPhotoStore()),
          ),
        ],
        child: ShotbookApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.text(
        'A very long photographic reference title that must stay within its card',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

class _MemorySavedPhotoStore implements SavedPhotoStore {
  @override
  Future<List<String>?> getStringList(String key) async => const [];

  @override
  Future<void> setStringList(String key, List<String> value) async {}
}

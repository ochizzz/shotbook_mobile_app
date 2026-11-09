import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/app/app.dart';
import 'package:shotbook/features/saved/application/saved_photo_provider.dart';
import 'package:shotbook/features/saved/data/saved_photo_repository.dart';

void main() {
  testWidgets(
    'Discover filters by category and search, with a resettable empty state',
    (tester) async {
      await tester.pumpWidget(ProviderScope(child: ShotbookApp()));

      await tester.tap(find.text('Street').first);
      await tester.pumpAndSettle();
      expect(find.text('A pause in Braga'), findsOneWidget);
      expect(find.text('Studio light study'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('discover-search-field')),
        'no such frame',
      );
      await tester.pumpAndSettle();
      expect(find.text('No frames match these filters.'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.text('Studio light study'), findsOneWidget);
    },
  );

  testWidgets('saving a reference adds it to Saved and can be undone', (
    tester,
  ) async {
    final store = _MemorySavedPhotoStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedPhotoRepositoryProvider.overrideWithValue(
            SavedPhotoRepository(store: store),
          ),
        ],
        child: ShotbookApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-card-portrait-studio-light')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-saved')));
    await tester.pumpAndSettle();
    expect(find.text('Studio light study'), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-card-portrait-studio-light')));
    await tester.pumpAndSettle();
    expect(find.text('No saved frames yet.'), findsOneWidget);
  });
}

class _MemorySavedPhotoStore implements SavedPhotoStore {
  List<String>? ids;

  @override
  Future<List<String>?> getStringList(String key) async => ids;

  @override
  Future<void> setStringList(String key, List<String> value) async {
    ids = List.of(value);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shotbook/features/saved/data/saved_photo_repository.dart';

void main() {
  test('saved photo IDs start empty and toggle on then off', () async {
    final store = MemorySavedPhotoStore();
    final repository = SavedPhotoRepository(store: store);

    expect(await repository.loadIds(), isEmpty);
    expect(await repository.toggle('frame-1'), {'frame-1'});
    expect(await repository.toggle('frame-1'), isEmpty);
  });

  test('saved photo IDs persist across repository instances', () async {
    final store = MemorySavedPhotoStore();
    await SavedPhotoRepository(store: store).toggle('frame-2');

    expect(await SavedPhotoRepository(store: store).loadIds(), {'frame-2'});
  });

  test(
    'rapid consecutive toggles apply in order without losing an update',
    () async {
      final store = MemorySavedPhotoStore();
      final repository = SavedPhotoRepository(store: store);

      await Future.wait([
        repository.toggle('frame-3'),
        repository.toggle('frame-3'),
      ]);

      expect(await repository.loadIds(), isEmpty);
    },
  );
}

class MemorySavedPhotoStore implements SavedPhotoStore {
  final Map<String, List<String>> values = {};

  @override
  Future<List<String>?> getStringList(String key) async => values[key];

  @override
  Future<void> setStringList(String key, List<String> value) async {
    values[key] = List.of(value);
  }
}

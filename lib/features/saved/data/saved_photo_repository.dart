import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SavedPhotoStore {
  Future<List<String>?> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);
}

class SharedPreferencesSavedPhotoStore implements SavedPhotoStore {
  SharedPreferencesSavedPhotoStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<String>?> getStringList(String key) =>
      _preferences.getStringList(key);

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _preferences.setStringList(key, value);
}

class SavedPhotoRepository {
  SavedPhotoRepository({SavedPhotoStore? store})
    : _store = store ?? SharedPreferencesSavedPhotoStore();

  static const storageKey = 'shotbook.saved_photo_ids';

  final SavedPhotoStore _store;
  Future<void> _writeQueue = Future<void>.value();

  Future<Set<String>> loadIds() async {
    final ids = await _store.getStringList(storageKey);
    return (ids ?? const <String>[]).toSet();
  }

  Future<Set<String>> toggle(String id) {
    final result = Completer<Set<String>>();
    _writeQueue = _writeQueue.then((_) async {
      try {
        final ids = await loadIds();
        if (!ids.add(id)) ids.remove(id);
        final sortedIds = ids.toList()..sort();
        await _store.setStringList(storageKey, sortedIds);
        result.complete(ids);
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<bool> contains(String id) async => (await loadIds()).contains(id);
}

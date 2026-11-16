import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'phone_profile.dart';

const myPhonePreferenceKey = 'shotbook.my_phone';

/// Phone saved on a previous run, or detected; `main` overrides it.
final initialPhoneProvider = Provider<String?>((ref) => null);

/// The phone recipes are worked out for. Chosen in Discover; detected from
/// the device model on first run (Samsung Galaxy S and Pixel), otherwise
/// a generic phone.
class MyPhoneNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(initialPhoneProvider) ?? fallbackPhoneId;

  Future<void> select(String id) async {
    if (id == state || !phoneLenses.containsKey(id)) return;
    state = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(myPhonePreferenceKey, id);
    } catch (_) {
      // Applies for this run if storage is unavailable.
    }
  }
}

final myPhoneProvider = NotifierProvider<MyPhoneNotifier, String>(
  MyPhoneNotifier.new,
);

/// Saved choice, else the detected model, else null.
Future<String?> loadMyPhone() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(myPhonePreferenceKey);
    if (saved != null && phoneLenses.containsKey(saved)) return saved;
  } catch (_) {}
  try {
    final info = await const MethodChannel('shotbook/pro_camera')
        .invokeMapMethod<String, Object?>('deviceModel')
        .timeout(const Duration(seconds: 2));
    return phoneIdForModel(
      '${info?['manufacturer'] ?? ''}',
      '${info?['model'] ?? ''}',
    );
  } catch (_) {
    return null;
  }
}

/// Camera guide id for an Android model ("samsung", "SM-S918B").
String? phoneIdForModel(String manufacturer, String model) {
  final m = model.toUpperCase().trim();
  final samsung = RegExp(r'^SM-S9(\d)(\d)').firstMatch(m);
  if (samsung != null) {
    final series = {
      0: 's22',
      1: 's23',
      2: 's24',
      3: 's25',
      4: 's26',
    }[int.parse(samsung.group(1)!)];
    if (series == null) return null;
    final variant = int.parse(samsung.group(2)!);
    if (variant == 8) return 'samsung-$series-ultra';
    if (series == 's25' && variant == 7) return 'samsung-s25-edge';
    return 'samsung-$series';
  }
  if (m.startsWith('SM-A')) return 'samsung-galaxy-a';
  final pixel = RegExp(r'^PIXEL (\d+)(A)?').firstMatch(m);
  if (pixel != null) {
    if (pixel.group(2) != null) return 'google-pixel-a';
    final id = 'google-pixel-${pixel.group(1)}';
    return phoneLenses.containsKey(id) ? id : null;
  }
  return null;
}

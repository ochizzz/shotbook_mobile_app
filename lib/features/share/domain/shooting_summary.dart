import '../../discover/domain/photo_reference.dart';

/// Short one-line forms of a recipe's shooting values, as on the photo hero
/// and the share card: "ISO 100 · 1/60 · f1.8 · 26 mm".
///
/// Catalog values are often long ("f/1.8 (fixed)", "24 mm (1×)",
/// "Auto, no slower than 1/500 s"); only the part before the first comma,
/// semicolon or bracket is kept.
String? shootingSummary(PhotoReference photo, {bool focal = true}) {
  final parts = [
    shortIso(photo.iso),
    shortShutter(photo.shutterSpeed),
    shortAperture(photo.aperture),
    if (focal) shortFocal(photo.focalLength),
  ].whereType<String>();
  return parts.isEmpty ? null : parts.join(' · ');
}

/// "Pixel 8 Pro · main, 1x": the phone and the lens or mode.
String? deviceSummary(PhotoReference photo) {
  final parts = [
    _leadingFull(photo.device),
    _leadingFull(photo.camera),
  ].whereType<String>();
  return parts.isEmpty ? null : parts.join(' · ');
}

/// The preset of the recipe, if it names one. Localized photos keep it in
/// their editing notes ("Preset" in English, "Пресет" in the Russian base).
String? presetOf(PhotoReference photo) {
  for (final value in [
    photo.presetName,
    photo.editingData['Preset'],
    photo.editingData['Пресет'],
  ]) {
    if (value != null && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

/// "ISO 100"; "ISO Auto" when the recipe leaves it to the phone.
String? shortIso(String? value) {
  final v = _leading(value);
  if (v == null) return null;
  final bare = v.replaceFirst(RegExp(r'^iso\s*', caseSensitive: false), '');
  return bare.isEmpty ? null : 'ISO $bare';
}

/// "1/60"; skipped when it is not a number ("Auto").
String? shortShutter(String? value) {
  final v = _leading(value);
  if (v == null || !_hasDigit(v)) return null;
  if (!v.contains('/')) return v;
  return v.replaceFirst(RegExp(r'\s*(s|с|sec|сек)\.?$'), '');
}

/// "f1.8"; skipped when it is not a number.
String? shortAperture(String? value) {
  final v = _leading(value);
  if (v == null || !_hasDigit(v)) return null;
  final bare = v.replaceFirst(
    RegExp(r'^[fƒ]\s*/?\s*', caseSensitive: false),
    '',
  );
  return 'f$bare';
}

/// "26 mm"; skipped when it is not a number.
String? shortFocal(String? value) {
  final v = _leading(value);
  if (v == null || !_hasDigit(v)) return null;
  return v;
}

bool _hasDigit(String value) => RegExp(r'\d').hasMatch(value);

String? _leading(String? value) {
  if (value == null) return null;
  final cut = value.split(RegExp(r'[,;(]')).first.trim();
  return cut.isEmpty ? null : cut;
}

/// Device and lens keep commas ("main, 1x"), only brackets are dropped.
String? _leadingFull(String? value) {
  if (value == null) return null;
  final cut = value.split('(').first.trim();
  return cut.isEmpty ? null : cut;
}

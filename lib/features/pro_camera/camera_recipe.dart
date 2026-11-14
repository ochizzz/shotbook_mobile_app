import '../discover/domain/photo_reference.dart';

/// Camera settings a photo's recipe asks for, parsed from its text fields
/// ("1/250 с", "ISO 100", "−0,3 EV", "70 мм (3×)", "5000 K", "Авто").
/// Null means "leave on automatic".
class CameraRecipe {
  const CameraRecipe({
    this.iso,
    this.exposureNs,
    this.ev,
    this.whiteBalance,
    this.zoom,
  });

  final int? iso;
  final int? exposureNs;
  final double? ev;

  /// One of the camera's white balance presets.
  final String? whiteBalance;

  /// Zoom ratio relative to the main (1×) lens.
  final double? zoom;

  bool get isEmpty =>
      iso == null &&
      exposureNs == null &&
      ev == null &&
      whiteBalance == null &&
      zoom == null;

  /// [mainEquivalentMm] is the phone's 1× lens in 35 mm terms (~23–26 mm).
  factory CameraRecipe.fromPhoto(
    PhotoReference photo, {
    double mainEquivalentMm = 24,
  }) {
    return CameraRecipe(
      iso: parseIso(photo.iso),
      exposureNs: parseShutterNs(photo.shutterSpeed),
      ev: parseEv(photo.exposureCompensation),
      whiteBalance: parseWhiteBalance(photo.whiteBalance),
      zoom:
          parseZoom(photo.focalLength, mainEquivalentMm) ??
          parseZoom(photo.camera, mainEquivalentMm),
    );
  }
}

final _number = RegExp(r'(\d+(?:[.,]\d+)?)');

double? _num(String text) {
  final m = _number.firstMatch(text);
  return m == null ? null : double.tryParse(m.group(1)!.replaceAll(',', '.'));
}

bool _isAuto(String? text) =>
    text == null ||
    text.trim().isEmpty ||
    RegExp(r'^\s*(авто|auto)\b', caseSensitive: false).hasMatch(text);

int? parseIso(String? text) {
  if (_isAuto(text)) return null;
  final value = _num(text!);
  if (value == null || value < 25 || value > 25600) return null;
  return value.round();
}

/// "1/250 с", "1/60 s", "2 с", "0.5 s", "30 с" → nanoseconds.
int? parseShutterNs(String? text) {
  if (_isAuto(text)) return null;
  final fraction = RegExp(r'1\s*/\s*(\d+(?:[.,]\d+)?)').firstMatch(text!);
  double? seconds;
  if (fraction != null) {
    final d = double.tryParse(fraction.group(1)!.replaceAll(',', '.'));
    if (d != null && d > 0) seconds = 1 / d;
  } else {
    seconds = _num(text);
  }
  if (seconds == null || seconds <= 0 || seconds > 30) return null;
  return (seconds * 1e9).round();
}

/// "−0,3 EV", "-1 EV", "+0.7", "0 EV" → stops.
double? parseEv(String? text) {
  if (_isAuto(text)) return null;
  final m = RegExp(r'([+\-−–]?)\s*(\d+(?:[.,]\d+)?)').firstMatch(text!);
  if (m == null) return null;
  final value = double.tryParse(m.group(2)!.replaceAll(',', '.'));
  if (value == null || value > 5) return null;
  return m.group(1)!.isNotEmpty && m.group(1) != '+' ? -value : value;
}

/// Kelvin values and words map to the nearest camera preset.
String? parseWhiteBalance(String? text) {
  if (_isAuto(text)) return null;
  final lower = text!.toLowerCase();
  final kelvin = RegExp(r'(\d{4,5})\s*[kк]').firstMatch(lower);
  if (kelvin != null) {
    final k = int.parse(kelvin.group(1)!);
    if (k < 3400) return 'incandescent';
    if (k < 4600) return 'fluorescent';
    if (k < 6000) return 'daylight';
    if (k < 7000) return 'cloudy';
    return 'shade';
  }
  if (lower.contains('ламп') ||
      lower.contains('tungsten') ||
      lower.contains('incandescent')) {
    return 'incandescent';
  }
  if (lower.contains('флуор') || lower.contains('fluor')) return 'fluorescent';
  if (lower.contains('тень') || lower.contains('shade')) return 'shade';
  if (lower.contains('облач') || lower.contains('cloud')) return 'cloudy';
  if (lower.contains('днев') ||
      lower.contains('солн') ||
      lower.contains('daylight') ||
      lower.contains('sun')) {
    return 'daylight';
  }
  return null;
}

/// "70 мм (3×)" → 3, "0.6×" → 0.6, "120 mm" → 120 / main lens.
double? parseZoom(String? text, double mainEquivalentMm) {
  if (text == null) return null;
  final times = RegExp(r'(\d+(?:[.,]\d+)?)\s*[×x]').firstMatch(text);
  if (times != null) {
    return double.tryParse(times.group(1)!.replaceAll(',', '.'));
  }
  final mm = RegExp(r'(\d+(?:[.,]\d+)?)\s*(мм|mm)').firstMatch(text);
  if (mm != null && mainEquivalentMm > 0) {
    final value = double.tryParse(mm.group(1)!.replaceAll(',', '.'));
    if (value != null && value > 0) {
      return double.parse((value / mainEquivalentMm).toStringAsFixed(1));
    }
  }
  return null;
}

import 'dart:math' as math;

import 'phone_profile.dart';

/// The real settings of the original photo (Unsplash EXIF).
class OriginalShot {
  const OriginalShot({
    required this.equivMm,
    required this.aperture,
    required this.seconds,
    required this.iso,
    this.camera,
    this.focalMm,
  });

  final String? camera;
  final double? focalMm;

  /// 35 mm equivalent focal length (crop factor applied).
  final double equivMm;
  final double aperture;
  final double seconds;
  final int iso;

  /// Crop factor of the original camera (1 for full frame).
  double get cropFactor =>
      focalMm == null || focalMm! <= 0 ? 1 : equivMm / focalMm!;

  static OriginalShot? fromJson(Object? json) {
    if (json is! Map) return null;
    final equiv = (json['equiv_mm'] as num?)?.toDouble();
    final aperture = (json['aperture'] as num?)?.toDouble();
    final iso = (json['iso'] as num?)?.toInt();
    final seconds = parseSeconds(json['shutter']?.toString());
    if (equiv == null || aperture == null || iso == null || seconds == null) {
      return null;
    }
    return OriginalShot(
      camera: json['camera'] as String?,
      focalMm: (json['focal_mm'] as num?)?.toDouble(),
      equivMm: equiv,
      aperture: aperture,
      seconds: seconds,
      iso: iso,
    );
  }

  Map<String, Object?> toJson() => {
    'camera': camera,
    'focal_mm': focalMm,
    'equiv_mm': equivMm,
    'aperture': aperture,
    'shutter': formatSeconds(seconds),
    'iso': iso,
  };
}

double? parseSeconds(String? text) {
  if (text == null) return null;
  final fraction = RegExp(r'^\s*(\d+)\s*/\s*(\d+(?:\.\d+)?)').firstMatch(text);
  if (fraction != null) {
    final a = double.parse(fraction.group(1)!);
    final b = double.parse(fraction.group(2)!);
    return b > 0 ? a / b : null;
  }
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value > 0 ? value : null;
}

/// "1/250", "1/2", "2" (seconds).
String formatSeconds(double s) {
  if (s >= 1) {
    return s == s.roundToDouble() ? '${s.round()}' : s.toStringAsFixed(1);
  }
  return '1/${(1 / s).round()}';
}

/// Things the recipe could not match exactly, shown as advice.
enum RecipeNote {
  /// The phone can't zoom in that far: step closer or crop.
  zoomShort,

  /// Beyond the longest lens: digital crop, some detail lost.
  digitalCrop,

  /// Wider than the widest lens: step back.
  zoomWide,

  /// The original background is much blurrier: use Portrait mode.
  portraitMode,

  /// Slower than is safe handheld: tripod or support.
  tripod,

  /// Not enough light even at the limits: night mode.
  nightMode,

  /// Brighter than the original even at the fastest settings.
  tooBright,

  /// The lens is only on the Pro models of this phone group.
  proLensOnly,
}

class PhoneRecipe {
  const PhoneRecipe({
    required this.lens,
    required this.zoom,
    required this.iso,
    required this.seconds,
    required this.notes,
    required this.evShortfall,
  });

  final PhoneLens lens;
  final double zoom;
  final int iso;
  final double seconds;
  final Set<RecipeNote> notes;

  /// Stops the result is darker (negative) or brighter (positive) than
  /// the original once the phone's limits are hit.
  final double evShortfall;
}

/// Categories where people move: keep the shutter fast enough.
const _peopleCategories = {
  'Portrait',
  'Street',
  'Full Body',
  'Couple',
  'Lifestyle',
};

const _blurCategories = {'Portrait', 'Couple', 'Full Body', 'Product'};

const isoStops = [
  50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, 800, 1000, //
  1250, 1600, 2000, 2500, 3200, 4000, 5000, 6400,
];

const _shutterDenominators = [
  8000, 6400, 5000, 4000, 3200, 2500, 2000, 1600, 1250, 1000, 800, 640, //
  500, 400, 320, 250, 200, 160, 125, 100, 80, 60, 50, 40, 30, 25, 20, 15,
  13, 10, 8, 6, 5, 4, 3,
];

double _nearestShutter(double s) {
  final stops = [
    for (final d in _shutterDenominators) 1 / d,
    0.5,
    0.8,
    1.0,
    1.5,
    2.0,
    3.0,
    4.0,
    6.0,
    8.0,
    10.0,
    15.0,
    20.0,
    30.0,
  ];
  return stops.reduce(
    (a, b) => (math.log(a / s)).abs() <= (math.log(b / s)).abs() ? a : b,
  );
}

int _nearestIso(double iso) => isoStops.reduce(
  (a, b) => (math.log(a / iso)).abs() <= (math.log(b / iso)).abs() ? a : b,
);

double _log2(double x) => math.log(x) / math.ln2;

/// The SHOTBOOK recipe algorithm: the original's framing, exposure and
/// depth of field, matched as closely as the phone allows.
///
/// 1. Framing: the longest lens not longer than the original focal
///    length, plus crop (zoom = equivalent ÷ main lens).
/// 2. Exposure: same brightness as the original. The shutter is kept
///    (moving people stay frozen, handheld stays sharp); ISO makes up for
///    the phone's aperture. At the ISO limits the shutter moves instead.
/// 3. Depth of field: compared through the equivalent aperture; much
///    more blur in the original means Portrait mode.
PhoneRecipe adaptShot(
  OriginalShot shot,
  PhoneProfile phone, {
  String category = '',
}) {
  final notes = <RecipeNote>{};
  final lenses = phone.lenses;
  final mainMm = phone.main.mm;

  // 1. Framing.
  var targetZoom = shot.equivMm / mainMm;
  if (targetZoom < phone.minZoom * 0.95) notes.add(RecipeNote.zoomWide);
  if (targetZoom > phone.maxZoom) {
    notes.add(RecipeNote.zoomShort);
    targetZoom = phone.maxZoom;
  }
  targetZoom = targetZoom.clamp(phone.minZoom, phone.maxZoom).toDouble();
  final targetMm = targetZoom * mainMm;
  final lens = lenses.lastWhere(
    (l) => l.mm <= targetMm * 1.08,
    orElse: () => lenses.first,
  );
  // Snap to the lens's own step when close (no needless crop).
  var zoom = (targetMm / lens.mm - 1).abs() < 0.08
      ? lens.mm / mainMm
      : targetZoom;
  zoom = double.parse(zoom.toStringAsFixed(1));
  if (lens == lenses.last && targetMm > lens.mm * 2) {
    notes.add(RecipeNote.digitalCrop);
  }
  if (lens.proOnly) notes.add(RecipeNote.proLensOnly);

  // 2. Exposure: H ∝ t · ISO / N².
  final people = _peopleCategories.contains(category);
  final handheldLimit = lens.kind == LensKind.main ? 1 / 15 : 1 / 30;
  // The slowest shutter that still freezes the subject: moving people
  // 1/250, cars 1/500, still scenes the handheld limit. An original
  // slower than that is kept (intended blur, panning).
  final motionLimit = math.max(
    shot.seconds,
    category == 'Car'
        ? 1 / 500
        : people
        ? 1 / 250
        : handheldLimit,
  );
  final exposure = shot.seconds * shot.iso / (shot.aperture * shot.aperture);
  final n2 = lens.aperture * lens.aperture;

  // Phones are noisy: spend spare shutter time on a lower ISO (towards
  // ISO 100), never slower than the subject allows.
  final forIso100 = exposure * n2 / 100;
  var seconds = math
      .min(math.max(shot.seconds, forIso100), motionLimit)
      .clamp(phone.shortestSeconds, phone.longestSeconds)
      .toDouble();
  var iso = exposure * n2 / seconds;
  if (iso < phone.isoMin) {
    iso = phone.isoMin.toDouble();
    seconds = math.max(exposure * n2 / iso, phone.shortestSeconds);
  } else if (iso > phone.isoMax) {
    iso = phone.isoMax.toDouble();
    var longest = phone.longestSeconds;
    if (people) longest = math.min(longest, math.max(shot.seconds, 1 / 30));
    seconds = math.min(exposure * n2 / iso, longest);
  }
  seconds = _nearestShutter(seconds);
  final isoStop = _nearestIso(iso);
  final got = seconds * isoStop / n2;
  final shortfall = _log2(got / exposure);
  if (shortfall < -0.7) notes.add(RecipeNote.nightMode);
  if (shortfall > 0.7) notes.add(RecipeNote.tooBright);
  if (seconds > handheldLimit + 1e-9) notes.add(RecipeNote.tripod);

  // 3. Depth of field (equivalent aperture, same framing).
  final originalEq = shot.aperture * shot.cropFactor;
  final phoneEq = lens.aperture * lens.cropFactor;
  if (_blurCategories.contains(category) && originalEq < phoneEq * 0.5) {
    notes.add(RecipeNote.portraitMode);
  }

  return PhoneRecipe(
    lens: lens,
    zoom: zoom,
    iso: isoStop,
    seconds: seconds,
    notes: notes,
    evShortfall: double.parse(shortfall.toStringAsFixed(1)),
  );
}

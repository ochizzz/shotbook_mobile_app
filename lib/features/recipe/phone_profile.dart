/// What a phone's cameras can do, for adapting a photo's original
/// settings to it. Figures are typical published specs (approximate).
library;

enum LensKind { ultraWide, main, tele, periscope }

class PhoneLens {
  const PhoneLens(this.kind, this.mm, this.aperture, {this.proOnly = false});

  final LensKind kind;

  /// 35 mm equivalent focal length.
  final double mm;

  /// Fixed f-number of the lens.
  final double aperture;

  /// Only the Pro models of a grouped entry have this lens.
  final bool proOnly;

  /// Crop factor of the sensor behind the lens: main cameras have the
  /// biggest sensors (1-inch ≈ 2.7), telephotos and ultra-wides smaller.
  double get cropFactor => switch (kind) {
    LensKind.main => aperture < 1.7 && mm <= 23 ? 3.6 : 4.6,
    LensKind.ultraWide => 6.5,
    LensKind.tele => 6.0,
    LensKind.periscope => 6.0,
  };
}

class PhoneProfile {
  const PhoneProfile({
    required this.id,
    required this.lenses,
    this.isoMin = 50,
    this.isoMax = 3200,
    this.shortestSeconds = 1 / 8000,
    this.longestSeconds = 10,
    this.zoomMax,
  });

  final String id;

  /// Ordered from widest to longest.
  final List<PhoneLens> lenses;
  final int isoMin;

  /// Highest ISO worth using (noise); phones go higher.
  final int isoMax;
  final double shortestSeconds;
  final double longestSeconds;

  /// Largest useful zoom ratio; defaults to 4× crop of the longest lens.
  final double? zoomMax;

  PhoneLens get main => lenses.firstWhere(
    (l) => l.kind == LensKind.main,
    orElse: () => lenses.first,
  );

  double get maxZoom => zoomMax ?? lenses.last.mm / main.mm * 4;

  double get minZoom => lenses.first.mm / main.mm;

  /// This phone with limits read from the real camera (PRO camera).
  PhoneProfile withLimits({
    int? isoMin,
    int? isoMax,
    double? shortestSeconds,
    double? longestSeconds,
    double? zoomMax,
    double? mainMm,
  }) {
    final scale = mainMm == null ? 1.0 : mainMm / main.mm;
    return PhoneProfile(
      id: id,
      lenses: [
        for (final l in lenses)
          PhoneLens(l.kind, l.mm * scale, l.aperture, proOnly: l.proOnly),
      ],
      isoMin: isoMin ?? this.isoMin,
      isoMax: isoMax == null ? this.isoMax : (isoMax < 3200 ? isoMax : 3200),
      shortestSeconds: shortestSeconds ?? this.shortestSeconds,
      longestSeconds: longestSeconds ?? this.longestSeconds,
      zoomMax: zoomMax ?? this.zoomMax,
    );
  }
}

const _uw = LensKind.ultraWide;
const _main = LensKind.main;
const _tele = LensKind.tele;
const _peri = LensKind.periscope;

/// Lenses per phone of the camera guide (`cameraDevices` ids).
const phoneLenses = <String, List<PhoneLens>>{
  'apple-iphone-17-pro': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.78),
    PhoneLens(_tele, 100, 2.8),
  ],
  'apple-iphone-17': [PhoneLens(_uw, 13, 2.2), PhoneLens(_main, 26, 1.6)],
  'apple-iphone-air': [PhoneLens(_main, 26, 1.6)],
  'apple-iphone-16-pro': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.78),
    PhoneLens(_peri, 120, 2.8),
  ],
  'apple-iphone-16': [PhoneLens(_uw, 13, 2.2), PhoneLens(_main, 26, 1.6)],
  'apple-iphone-16e': [PhoneLens(_main, 26, 1.6)],
  'apple-iphone-15-pro-max': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.78),
    PhoneLens(_peri, 120, 2.8),
  ],
  'apple-iphone-15-pro': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.78),
    PhoneLens(_tele, 77, 2.8),
  ],
  'apple-iphone-15': [PhoneLens(_uw, 13, 2.4), PhoneLens(_main, 26, 1.6)],
  'apple-iphone-14-pro': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.78),
    PhoneLens(_tele, 77, 2.8),
  ],
  'apple-iphone-14': [PhoneLens(_uw, 13, 2.4), PhoneLens(_main, 26, 1.5)],
  'apple-iphone-se-3': [PhoneLens(_main, 28, 1.8)],
  'samsung-s26-ultra': [
    PhoneLens(_uw, 13, 1.9),
    PhoneLens(_main, 23, 1.4),
    PhoneLens(_tele, 69, 2.4),
    PhoneLens(_peri, 111, 2.9),
  ],
  'samsung-s26': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.8),
    PhoneLens(_tele, 69, 2.4),
  ],
  'samsung-s25-ultra': [
    PhoneLens(_uw, 13, 1.9),
    PhoneLens(_main, 24, 1.7),
    PhoneLens(_tele, 69, 2.4),
    PhoneLens(_peri, 111, 3.4),
  ],
  'samsung-s25-edge': [PhoneLens(_uw, 13, 2.2), PhoneLens(_main, 24, 1.7)],
  'samsung-s25': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.8),
    PhoneLens(_tele, 69, 2.4),
  ],
  'samsung-s24-ultra': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.7),
    PhoneLens(_tele, 69, 2.4),
    PhoneLens(_peri, 111, 3.4),
  ],
  'samsung-s24': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 24, 1.8),
    PhoneLens(_tele, 69, 2.4),
  ],
  'samsung-s23-ultra': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 23, 1.7),
    PhoneLens(_tele, 69, 2.4),
    PhoneLens(_peri, 230, 4.9),
  ],
  'samsung-s23': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 23, 1.8),
    PhoneLens(_tele, 69, 2.4),
  ],
  'samsung-s22-ultra': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 23, 1.8),
    PhoneLens(_tele, 69, 2.4),
    PhoneLens(_peri, 230, 4.9),
  ],
  'samsung-s22': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 23, 1.8),
    PhoneLens(_tele, 69, 2.4),
  ],
  'samsung-galaxy-a': [PhoneLens(_uw, 13, 2.2), PhoneLens(_main, 26, 1.8)],
  'google-pixel-10': [
    PhoneLens(_uw, 12, 1.7),
    PhoneLens(_main, 24, 1.68),
    PhoneLens(_peri, 110, 2.8),
  ],
  'google-pixel-9': [
    PhoneLens(_uw, 13, 1.7),
    PhoneLens(_main, 25, 1.68),
    PhoneLens(_peri, 110, 2.8, proOnly: true),
  ],
  'google-pixel-8': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 25, 1.68),
    PhoneLens(_peri, 113, 2.8, proOnly: true),
  ],
  'google-pixel-7': [
    PhoneLens(_uw, 13, 2.2),
    PhoneLens(_main, 25, 1.85),
    PhoneLens(_peri, 120, 3.5, proOnly: true),
  ],
  'google-pixel-a': [PhoneLens(_uw, 13, 2.2), PhoneLens(_main, 26, 1.7)],
  'xiaomi-17-ultra': [
    PhoneLens(_uw, 14, 2.2),
    PhoneLens(_main, 23, 1.67),
    PhoneLens(_peri, 75, 2.4),
  ],
  'xiaomi-15-ultra': [
    PhoneLens(_uw, 14, 2.2),
    PhoneLens(_main, 23, 1.63),
    PhoneLens(_tele, 70, 1.8),
    PhoneLens(_peri, 100, 2.6),
  ],
  'xiaomi-15': [
    PhoneLens(_uw, 14, 2.2),
    PhoneLens(_main, 23, 1.62),
    PhoneLens(_tele, 60, 2.0),
  ],
  'xiaomi-14-ultra': [
    PhoneLens(_uw, 12, 1.8),
    PhoneLens(_main, 23, 1.63),
    PhoneLens(_tele, 75, 1.8),
    PhoneLens(_peri, 120, 2.5),
  ],
  'xiaomi-14': [
    PhoneLens(_uw, 14, 2.2),
    PhoneLens(_main, 23, 1.6),
    PhoneLens(_tele, 75, 2.0),
  ],
  'xiaomi-13-ultra': [
    PhoneLens(_uw, 12, 1.8),
    PhoneLens(_main, 23, 1.9),
    PhoneLens(_tele, 75, 1.8),
    PhoneLens(_peri, 120, 3.0),
  ],
  'xiaomi-13-pro': [
    PhoneLens(_uw, 14, 2.2),
    PhoneLens(_main, 23, 1.9),
    PhoneLens(_tele, 75, 2.0),
  ],
  'redmi-note-pro': [PhoneLens(_uw, 16, 2.2), PhoneLens(_main, 24, 1.65)],
  'oneplus-13': [
    PhoneLens(_uw, 14, 2.0),
    PhoneLens(_main, 23, 1.6),
    PhoneLens(_peri, 73, 2.6),
  ],
  'oneplus-12': [
    PhoneLens(_uw, 14, 2.2),
    PhoneLens(_main, 23, 1.6),
    PhoneLens(_peri, 70, 2.6),
  ],
  'oneplus-11': [
    PhoneLens(_uw, 14, 2.2),
    PhoneLens(_main, 24, 1.8),
    PhoneLens(_tele, 48, 2.0),
  ],
  'oneplus-10-pro': [
    PhoneLens(_uw, 14, 2.2),
    PhoneLens(_main, 23, 1.8),
    PhoneLens(_tele, 77, 2.4),
  ],
  'oppo-find-x8-pro': [
    PhoneLens(_uw, 15, 2.0),
    PhoneLens(_main, 23, 1.6),
    PhoneLens(_tele, 73, 2.6),
    PhoneLens(_peri, 135, 4.3),
  ],
  'oppo-find-x7-ultra': [
    PhoneLens(_uw, 15, 2.0),
    PhoneLens(_main, 23, 1.8),
    PhoneLens(_tele, 65, 2.6),
    PhoneLens(_peri, 135, 4.3),
  ],
  'vivo-x200-pro': [
    PhoneLens(_uw, 15, 2.0),
    PhoneLens(_main, 23, 1.57),
    PhoneLens(_peri, 85, 2.67),
  ],
  'vivo-x100-pro': [
    PhoneLens(_uw, 15, 2.0),
    PhoneLens(_main, 23, 1.75),
    PhoneLens(_peri, 100, 2.5),
  ],
  'honor-magic7-pro': [
    PhoneLens(_uw, 13, 2.0),
    PhoneLens(_main, 23, 1.4),
    PhoneLens(_peri, 70, 3.0),
  ],
  'honor-magic6-pro': [
    PhoneLens(_uw, 13, 2.0),
    PhoneLens(_main, 23, 1.4),
    PhoneLens(_peri, 60, 2.6),
  ],
  'nothing-phone-3': [
    PhoneLens(_uw, 15, 2.2),
    PhoneLens(_main, 24, 1.68),
    PhoneLens(_peri, 70, 2.68),
  ],
  'nothing-phone-2': [PhoneLens(_uw, 14, 2.2), PhoneLens(_main, 24, 1.88)],
  'other-smartphone': [PhoneLens(_uw, 13, 2.2), PhoneLens(_main, 25, 1.8)],
};

const fallbackPhoneId = 'other-smartphone';

PhoneProfile phoneProfile(String? deviceId) {
  final id = phoneLenses.containsKey(deviceId) ? deviceId! : fallbackPhoneId;
  return PhoneProfile(id: id, lenses: phoneLenses[id]!);
}

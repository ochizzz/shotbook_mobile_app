import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../discover/domain/photo_reference.dart';

/// The "look" of a photo: the processing that turns a plain capture into
/// the reference's style (black and white, warm film, contrast, vignette…).
/// Shown live over the viewfinder and baked into the saved JPEG.
/// Every value runs −1…1 (0 = untouched) except fade, vignette and grain
/// (0…1).
@immutable
class PhotoLook {
  const PhotoLook({
    this.id = 'none',
    this.brightness = 0,
    this.contrast = 0,
    this.saturation = 0,
    this.warmth = 0,
    this.tint = 0,
    this.fade = 0,
    this.shadows = 0,
    this.highlights = 0,
    this.vignette = 0,
    this.grain = 0,
    this.mono = false,
  });

  /// Preset id ("none", "mono", "film"…), "recipe" or "custom".
  final String id;
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final double tint;
  final double fade;
  final double shadows;
  final double highlights;
  final double vignette;
  final double grain;
  final bool mono;

  static const none = PhotoLook();

  bool get isNone =>
      brightness == 0 &&
      contrast == 0 &&
      saturation == 0 &&
      warmth == 0 &&
      tint == 0 &&
      fade == 0 &&
      shadows == 0 &&
      highlights == 0 &&
      vignette == 0 &&
      grain == 0 &&
      !mono;

  PhotoLook copyWith({
    String? id,
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? tint,
    double? fade,
    double? shadows,
    double? highlights,
    double? vignette,
    double? grain,
    bool? mono,
  }) => PhotoLook(
    id: id ?? this.id,
    brightness: (brightness ?? this.brightness).clamp(-1.0, 1.0),
    contrast: (contrast ?? this.contrast).clamp(-1.0, 1.0),
    saturation: (saturation ?? this.saturation).clamp(-1.0, 1.0),
    warmth: (warmth ?? this.warmth).clamp(-1.0, 1.0),
    tint: (tint ?? this.tint).clamp(-1.0, 1.0),
    fade: (fade ?? this.fade).clamp(0.0, 1.0),
    shadows: (shadows ?? this.shadows).clamp(-1.0, 1.0),
    highlights: (highlights ?? this.highlights).clamp(-1.0, 1.0),
    vignette: (vignette ?? this.vignette).clamp(0.0, 1.0),
    grain: (grain ?? this.grain).clamp(0.0, 1.0),
    mono: mono ?? this.mono,
  );

  /// 4×5 colour matrix (offsets in 0…255), the same layout Flutter's
  /// ColorFilter.matrix and Android's ColorMatrix use.
  List<double> get colorMatrix {
    var m = _identity();
    // Exposure-like brightness: scale, so blacks stay black.
    if (brightness != 0) m = _mul(_scale(1 + brightness * 0.6), m);
    // Shadows: lift (+) or deepen (−) the low end with an offset that is
    // balanced by a slight scale so whites stay put.
    if (shadows != 0) {
      final lift = shadows * 22;
      m = _mul(_scaleOffset(1 - lift / 255, lift), m);
    }
    // Highlights: pull down (−) or push (+) the top end.
    if (highlights != 0) m = _mul(_scale(1 + highlights * 0.12), m);
    if (contrast != 0) {
      final c = 1 + contrast * 0.6;
      m = _mul(_scaleOffset(c, 127.5 * (1 - c)), m);
    }
    final sat = mono ? 0.0 : 1 + saturation * 0.8;
    if (sat != 1) m = _mul(_saturation(sat), m);
    if (warmth != 0 || tint != 0) {
      m = _mul(_channelOffsets(warmth * 28, -tint * 18, -warmth * 28), m);
    }
    // Fade: raise blacks and soften whites, like matte film.
    if (fade != 0) {
      final f = fade * 0.18;
      m = _mul(_scaleOffset(1 - f, f * 255), m);
    }
    return m;
  }

  // 4×5 matrices as 20-value lists, row-major.
  static List<double> _identity() => [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ];

  static List<double> _scale(double s) => _scaleOffset(s, 0);

  static List<double> _scaleOffset(double s, double o) => [
    s, 0, 0, 0, o, //
    0, s, 0, 0, o,
    0, 0, s, 0, o,
    0, 0, 0, 1, 0,
  ];

  static List<double> _channelOffsets(double r, double g, double b) => [
    1, 0, 0, 0, r, //
    0, 1, 0, 0, g,
    0, 0, 1, 0, b,
    0, 0, 0, 1, 0,
  ];

  static List<double> _saturation(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final i = 1 - s;
    return [
      lr * i + s, lg * i, lb * i, 0, 0, //
      lr * i, lg * i + s, lb * i, 0, 0,
      lr * i, lg * i, lb * i + s, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }

  /// a ∘ b: apply b first, then a.
  static List<double> _mul(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0);
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        var v = col == 4 ? a[row * 5 + 4] : 0.0;
        for (var k = 0; k < 4; k++) {
          v += a[row * 5 + k] * b[k * 5 + col];
        }
        out[row * 5 + col] = v;
      }
    }
    return out;
  }
}

/// Ready-made looks offered in the camera.
const lookPresets = <PhotoLook>[
  PhotoLook(),
  PhotoLook(id: 'mono', mono: true, contrast: 0.1),
  PhotoLook(
    id: 'noir',
    mono: true,
    contrast: 0.45,
    shadows: -0.35,
    vignette: 0.45,
    grain: 0.25,
  ),
  PhotoLook(
    id: 'film',
    warmth: 0.25,
    fade: 0.25,
    saturation: -0.12,
    contrast: -0.05,
    grain: 0.3,
  ),
  PhotoLook(id: 'warm', warmth: 0.3, saturation: 0.05),
  PhotoLook(id: 'cool', warmth: -0.28, saturation: -0.05, tint: 0.05),
  PhotoLook(id: 'faded', fade: 0.45, contrast: -0.18, saturation: -0.25),
  PhotoLook(id: 'vivid', saturation: 0.35, contrast: 0.18),
  PhotoLook(
    id: 'cinema',
    contrast: 0.22,
    saturation: -0.12,
    warmth: 0.08,
    tint: -0.08,
    shadows: -0.2,
    vignette: 0.25,
  ),
];

/// English names (translated with context.tr).
const lookNames = {
  'none': 'Original',
  'recipe': 'From photo',
  'custom': 'Custom',
  'mono': 'B&W',
  'noir': 'Noir',
  'film': 'Warm film',
  'warm': 'Warm',
  'cool': 'Cool',
  'faded': 'Faded',
  'vivid': 'Vivid',
  'cinema': 'Cinema',
};

final _number = RegExp(r'([+\-−–]?)\s*(\d+(?:[.,]\d+)?)');

double? _signed(String text) {
  final m = _number.firstMatch(text);
  if (m == null) return null;
  final v = double.tryParse(m.group(2)!.replaceAll(',', '.'));
  if (v == null) return null;
  return (m.group(1)!.isNotEmpty && m.group(1) != '+') ? -v : v;
}

bool _has(String text, List<String> words) =>
    words.any((w) => text.contains(w));

const _monoWords = [
  'ч/б',
  'чб ',
  'черно-бел',
  'чёрно-бел',
  'монохром',
  '«моно»',
  ' моно',
  'b&w',
  'b/w',
  'black and white',
  'black & white',
  'black-and-white',
  'monochrome',
  'mono ',
  'noir',
];

/// The look a photo's recipe describes: its preset name, the editing
/// steps (contrast, shadows, vignette…), warmer/cooler white balance and
/// black-and-white hints anywhere in the recipe. Russian and English.
PhotoLook lookFromPhoto(PhotoReference photo) {
  var look = const PhotoLook(id: 'recipe');
  final all = <String>[
    photo.title,
    photo.whiteBalance ?? '',
    photo.presetName ?? '',
    ...photo.editingData.keys,
    ...photo.editingData.values,
  ].join(' | ').toLowerCase();
  if (_has(' $all ', _monoWords)) look = look.copyWith(mono: true);

  for (final entry in photo.editingData.entries) {
    final key = entry.key.toLowerCase();
    final value = entry.value.toLowerCase();
    final n = _signed(value);
    // Editors use −100…100; small values (|n| ≤ 10) are on a ±10 scale.
    double unit(double v) => v.abs() <= 10 ? v / 10 : v / 100;
    if (_has(key, ['пресет', 'preset', 'фильтр', 'filter', 'стиль', 'style'])) {
      if (_has(value, ['тёпл', 'тепл', 'warm'])) {
        look = look.copyWith(warmth: look.warmth + 0.2);
      }
      if (_has(value, ['плён', 'плен', 'film', 'kodak', 'portra', 'fuji'])) {
        look = look.copyWith(fade: look.fade + 0.15, grain: look.grain + 0.2);
      }
      if (_has(value, ['холод', 'cool', 'cold'])) {
        look = look.copyWith(warmth: look.warmth - 0.2);
      }
      if (_has(value, ['ярк', 'vivid', 'насыщ'])) {
        look = look.copyWith(saturation: look.saturation + 0.2);
      }
      if (_has(value, ['мягк', 'soft'])) {
        look = look.copyWith(contrast: look.contrast - 0.1);
      }
      if (_has(value, ['кино', 'cinem'])) {
        look = look.copyWith(
          contrast: look.contrast + 0.15,
          saturation: look.saturation - 0.1,
          tint: look.tint - 0.05,
        );
      }
    } else if (n != null && _has(key, ['контраст', 'contrast'])) {
      look = look.copyWith(contrast: look.contrast + unit(n));
    } else if (n != null &&
        _has(key, ['насыщ', 'saturation', 'вибранс', 'vibrance'])) {
      look = look.copyWith(saturation: look.saturation + unit(n));
    } else if (n != null && _has(key, ['экспоз', 'exposure'])) {
      // Exposure edits are in stops (±0.3 …).
      look = look.copyWith(brightness: look.brightness + n * 0.5);
    } else if (n != null && _has(key, ['тени', 'shadow'])) {
      look = look.copyWith(shadows: look.shadows + unit(n));
    } else if (n != null && _has(key, ['света', 'highlight'])) {
      look = look.copyWith(highlights: look.highlights + unit(n));
    } else if (n != null && _has(key, ['чёрн', 'черн', 'black'])) {
      look = n > 0
          ? look.copyWith(fade: look.fade + unit(n) / 2)
          : look.copyWith(shadows: look.shadows + unit(n) / 2);
    } else if (n != null && _has(key, ['виньет', 'vignette'])) {
      // Lightroom: negative = darker edges.
      look = look.copyWith(vignette: n < 0 ? unit(n).abs() * 1.5 : 0);
    } else if (n != null && _has(key, ['зерно', 'grain', 'шум'])) {
      look = look.copyWith(grain: look.grain + unit(n).abs());
    } else if (n != null && _has(key, ['тепл', 'temperature', 'warmth'])) {
      look = look.copyWith(warmth: look.warmth + unit(n) * 0.6);
    } else if (n != null && _has(key, ['оттен', 'tint'])) {
      look = look.copyWith(tint: look.tint + unit(n) * 0.6);
    } else if (_has(key, ['цвет', 'color', 'colour'])) {
      if (_has(value, ['тепл', 'warm', 'оранж', 'orange', 'жёлт', 'yellow'])) {
        look = look.copyWith(warmth: look.warmth + 0.08);
      }
      if (_has(value, ['холод', 'cool', 'син', 'blue', 'бирюз', 'teal'])) {
        look = look.copyWith(warmth: look.warmth - 0.06);
      }
    }
  }

  // "Авто, теплее на +3" / "Auto, warmer" in the white balance note.
  final wb = (photo.whiteBalance ?? '').toLowerCase();
  if (_has(wb, ['тепл', 'warm'])) {
    final n = _signed(wb.substring(wb.indexOf(RegExp('тепл|warm'))));
    look = look.copyWith(
      warmth: look.warmth + (n == null ? 0.12 : math.min(n.abs(), 10) / 25),
    );
  } else if (_has(wb, ['холод', 'cool'])) {
    final n = _signed(wb.substring(wb.indexOf(RegExp('холод|cool'))));
    look = look.copyWith(
      warmth: look.warmth - (n == null ? 0.12 : math.min(n.abs(), 10) / 25),
    );
  }
  return look.isNone ? const PhotoLook(id: 'recipe') : look;
}

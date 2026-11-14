import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_recipe.dart';

/// What the phone's camera allows. Unsupported controls stay disabled.
class ProCameraCapabilities {
  const ProCameraCapabilities({
    required this.available,
    this.manualSensor = false,
    this.raw = false,
    this.isoMin = 50,
    this.isoMax = 3200,
    this.exposureMinNs = 100000,
    this.exposureMaxNs = 1000000000,
    this.evMin = 0,
    this.evMax = 0,
    this.evStep = 1,
    this.manualFocus = false,
    this.minFocusDiopters = 0,
    this.awbModes = const ['auto'],
    this.zoomMin = 1,
    this.zoomMax = 1,
    this.mainEquivalentMm = 24,
  });

  factory ProCameraCapabilities.fromMap(Map<Object?, Object?> map) {
    double d(String key, double fallback) =>
        (map[key] as num?)?.toDouble() ?? fallback;
    int i(String key, int fallback) => (map[key] as num?)?.toInt() ?? fallback;
    return ProCameraCapabilities(
      available: map['available'] == true,
      manualSensor: map['manualSensor'] == true,
      raw: map['raw'] == true,
      isoMin: i('isoMin', 50),
      isoMax: i('isoMax', 3200),
      exposureMinNs: i('exposureMinNs', 100000),
      exposureMaxNs: i('exposureMaxNs', 1000000000),
      evMin: i('evMin', 0),
      evMax: i('evMax', 0),
      evStep: d('evStep', 1),
      manualFocus: map['manualFocus'] == true,
      minFocusDiopters: d('minFocusDiopters', 0),
      awbModes: [
        for (final mode in (map['awbModes'] as List?) ?? const ['auto'])
          '$mode',
      ],
      zoomMin: d('zoomMin', 1),
      zoomMax: d('zoomMax', 1),
      mainEquivalentMm: d('mainEquivalentMm', 24),
    );
  }

  final bool available;
  final bool manualSensor;
  final bool raw;
  final int isoMin;
  final int isoMax;
  final int exposureMinNs;
  final int exposureMaxNs;
  final int evMin;
  final int evMax;
  final double evStep;
  final bool manualFocus;
  final double minFocusDiopters;
  final List<String> awbModes;
  final double zoomMin;
  final double zoomMax;
  final double mainEquivalentMm;

  bool get exposureCompensation => evMax > evMin;
  bool get zoomable => zoomMax > zoomMin;
}

/// The controls the user set. Auto flags win over the manual values.
@immutable
class ProCameraSettings {
  const ProCameraSettings({
    this.autoExposure = true,
    this.iso = 100,
    this.exposureNs = 8000000,
    this.ev = 0,
    this.whiteBalance = 'auto',
    this.autoFocus = true,
    this.focusDiopters = 0,
    this.zoom = 1,
    this.raw = false,
  });

  final bool autoExposure;
  final int iso;
  final int exposureNs;

  /// Exposure compensation in stops (used in automatic exposure).
  final double ev;
  final String whiteBalance;
  final bool autoFocus;
  final double focusDiopters;
  final double zoom;
  final bool raw;

  ProCameraSettings copyWith({
    bool? autoExposure,
    int? iso,
    int? exposureNs,
    double? ev,
    String? whiteBalance,
    bool? autoFocus,
    double? focusDiopters,
    double? zoom,
    bool? raw,
  }) => ProCameraSettings(
    autoExposure: autoExposure ?? this.autoExposure,
    iso: iso ?? this.iso,
    exposureNs: exposureNs ?? this.exposureNs,
    ev: ev ?? this.ev,
    whiteBalance: whiteBalance ?? this.whiteBalance,
    autoFocus: autoFocus ?? this.autoFocus,
    focusDiopters: focusDiopters ?? this.focusDiopters,
    zoom: zoom ?? this.zoom,
    raw: raw ?? this.raw,
  );

  /// Applies a photo's recipe within what the phone allows. Manual ISO and
  /// shutter are only used together, and only on phones with manual sensor
  /// control; otherwise exposure stays automatic with the recipe's EV.
  ProCameraSettings withRecipe(CameraRecipe recipe, ProCameraCapabilities c) {
    var next = this;
    final manual =
        c.manualSensor && recipe.iso != null && recipe.exposureNs != null;
    if (manual) {
      next = next.copyWith(
        autoExposure: false,
        iso: recipe.iso!.clamp(c.isoMin, c.isoMax),
        exposureNs: recipe.exposureNs!.clamp(c.exposureMinNs, c.exposureMaxNs),
      );
    } else {
      next = next.copyWith(autoExposure: true);
    }
    if (recipe.ev != null && c.exposureCompensation) {
      final steps = (recipe.ev! / c.evStep).round().clamp(c.evMin, c.evMax);
      next = next.copyWith(ev: steps * c.evStep);
    }
    if (recipe.whiteBalance != null &&
        c.awbModes.contains(recipe.whiteBalance)) {
      next = next.copyWith(whiteBalance: recipe.whiteBalance);
    }
    if (recipe.zoom != null && c.zoomable) {
      next = next.copyWith(zoom: recipe.zoom!.clamp(c.zoomMin, c.zoomMax));
    }
    return next;
  }
}

class ProCameraPhotoResult {
  const ProCameraPhotoResult({required this.jpeg, this.dng});

  final String jpeg;
  final String? dng;
}

/// Talks to the native camera (Android, ProCameraPlugin.kt).
class ProCameraController extends ChangeNotifier {
  ProCameraController({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('shotbook/pro_camera');

  final MethodChannel _channel;

  ProCameraCapabilities capabilities = const ProCameraCapabilities(
    available: false,
  );
  ProCameraSettings settings = const ProCameraSettings();
  int? textureId;
  int previewWidth = 4;
  int previewHeight = 3;
  bool rawAvailable = false;
  bool busy = false;

  /// Preview aspect ratio in portrait (width / height).
  double get portraitAspectRatio =>
      math.min(previewWidth, previewHeight) /
      math.max(previewWidth, previewHeight);

  Future<bool> loadCapabilities() async {
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>(
        'capabilities',
      );
      capabilities = ProCameraCapabilities.fromMap(map ?? const {});
    } on MissingPluginException {
      capabilities = const ProCameraCapabilities(available: false);
    }
    notifyListeners();
    return capabilities.available;
  }

  Future<void> open() async {
    final map = await _channel.invokeMapMethod<Object?, Object?>('open');
    textureId = (map?['textureId'] as num?)?.toInt();
    previewWidth = (map?['previewWidth'] as num?)?.toInt() ?? 4;
    previewHeight = (map?['previewHeight'] as num?)?.toInt() ?? 3;
    rawAvailable = map?['raw'] == true && capabilities.raw;
    if (!rawAvailable && settings.raw) settings = settings.copyWith(raw: false);
    await _push();
    notifyListeners();
  }

  Future<void> update(ProCameraSettings next) async {
    settings = next;
    notifyListeners();
    await _push();
  }

  Future<void> _push() async {
    if (textureId == null) return;
    final c = capabilities;
    await _channel.invokeMethod<void>('setControls', {
      'autoExposure': settings.autoExposure || !c.manualSensor,
      'iso': settings.iso,
      'exposureNs': settings.exposureNs,
      'ev': c.exposureCompensation ? (settings.ev / c.evStep).round() : 0,
      'awb': settings.whiteBalance,
      'autoFocus': settings.autoFocus || !c.manualFocus,
      'focusDiopters': settings.focusDiopters,
      'zoom': settings.zoom,
    });
  }

  Future<ProCameraPhotoResult> capture() async {
    busy = true;
    notifyListeners();
    try {
      final map = await _channel.invokeMapMethod<Object?, Object?>('capture', {
        'raw': settings.raw && rawAvailable,
      });
      return ProCameraPhotoResult(
        jpeg: '${map?['jpeg']}',
        dng: map?['dng'] as String?,
      );
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> close() async {
    textureId = null;
    try {
      await _channel.invokeMethod<void>('close');
    } on MissingPluginException {
      // Nothing to close on platforms without the native camera.
    }
  }
}

/// "1/250", "1/8", "0.5″", "1″" — how photographers write shutter speeds.
String formatShutter(int ns) {
  final seconds = ns / 1e9;
  if (seconds >= 0.4) {
    final s = seconds >= 1
        ? seconds.toStringAsFixed(seconds % 1 == 0 ? 0 : 1)
        : seconds.toStringAsFixed(1);
    return '$s″';
  }
  return '1/${(1 / seconds).round()}';
}

/// Standard shutter stops between [minNs] and [maxNs], for the dial.
List<int> shutterStops(int minNs, int maxNs) {
  const denominators = [
    8000, 4000, 2000, 1000, 500, 250, 125, 60, 30, 15, 8, 4, 2, //
  ];
  final stops = <int>[
    for (final d in denominators) (1e9 / d).round(),
    500000000,
    1000000000,
  ];
  return [
    for (final ns in stops)
      if (ns >= minNs && ns <= maxNs) ns,
  ];
}

/// Standard ISO stops between [min] and [max], for the dial.
List<int> isoStops(int min, int max) => [
  for (final iso in const [
    50,
    64,
    100,
    125,
    200,
    250,
    400,
    640,
    800,
    1600,
    3200,
    6400,
    12800,
  ])
    if (iso >= min && iso <= max) iso,
];

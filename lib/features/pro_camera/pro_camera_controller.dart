import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'camera_recipe.dart';
import 'photo_look.dart';

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
    this.wbMode = 'presets',
    this.kelvinMin = 2000,
    this.kelvinMax = 10000,
    this.zoomMin = 1,
    this.zoomMax = 1,
    this.mainEquivalentMm = 24,
    this.flash = false,
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
      wbMode: map['wbMode'] as String? ?? 'presets',
      kelvinMin: i('kelvinMin', 2000),
      kelvinMax: i('kelvinMax', 10000),
      zoomMin: d('zoomMin', 1),
      zoomMax: d('zoomMax', 1),
      mainEquivalentMm: d('mainEquivalentMm', 24),
      flash: map['flash'] == true,
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

  /// "cct" or "gains": any Kelvin value; "presets": nearest preset only.
  final String wbMode;
  final int kelvinMin;
  final int kelvinMax;
  final double zoomMin;
  final double zoomMax;
  final double mainEquivalentMm;
  final bool flash;

  bool get exposureCompensation => evMax > evMin;
  bool get zoomable => zoomMax > zoomMin;
  bool get preciseKelvin => wbMode == 'cct' || wbMode == 'gains';
}

/// The controls the user set. Auto flags win over the manual values.
@immutable
class ProCameraSettings {
  const ProCameraSettings({
    this.autoExposure = true,
    this.iso = 100,
    this.exposureNs = 8000000,
    this.ev = 0,
    this.autoWhiteBalance = true,
    this.kelvin = 5500,
    this.autoFocus = true,
    this.focusDiopters = 0,
    this.zoom = 1,
    this.raw = false,
    this.flash = 'off',
    this.look = PhotoLook.none,
  });

  final bool autoExposure;
  final int iso;
  final int exposureNs;

  /// Exposure compensation in stops (used in automatic exposure).
  final double ev;
  final bool autoWhiteBalance;
  final int kelvin;
  final bool autoFocus;
  final double focusDiopters;
  final double zoom;
  final bool raw;

  /// "off", "auto" or "on".
  final String flash;

  /// Processing applied live and baked into the JPEG (RAW stays clean).
  final PhotoLook look;

  ProCameraSettings copyWith({
    bool? autoExposure,
    int? iso,
    int? exposureNs,
    double? ev,
    bool? autoWhiteBalance,
    int? kelvin,
    bool? autoFocus,
    double? focusDiopters,
    double? zoom,
    bool? raw,
    String? flash,
    PhotoLook? look,
  }) => ProCameraSettings(
    autoExposure: autoExposure ?? this.autoExposure,
    iso: iso ?? this.iso,
    exposureNs: exposureNs ?? this.exposureNs,
    ev: ev ?? this.ev,
    autoWhiteBalance: autoWhiteBalance ?? this.autoWhiteBalance,
    kelvin: kelvin ?? this.kelvin,
    autoFocus: autoFocus ?? this.autoFocus,
    focusDiopters: focusDiopters ?? this.focusDiopters,
    zoom: zoom ?? this.zoom,
    raw: raw ?? this.raw,
    flash: flash ?? this.flash,
    look: look ?? this.look,
  );

  /// Everything back to automatic at 1×; keeps the RAW choice.
  ProCameraSettings reset() => ProCameraSettings(raw: raw, flash: flash);

  bool get isDefault =>
      autoExposure &&
      ev == 0 &&
      autoWhiteBalance &&
      autoFocus &&
      zoom == 1 &&
      look.isNone;

  /// Applies a photo's recipe within what the phone allows. Manual ISO and
  /// shutter are only used together, and only on phones with manual sensor
  /// control; otherwise exposure stays automatic with the recipe's EV.
  ProCameraSettings withRecipe(
    CameraRecipe recipe,
    ProCameraCapabilities c, {
    PhotoLook? look,
  }) {
    var next = look == null ? this : copyWith(look: look);
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
    if (recipe.kelvin != null) {
      next = next.copyWith(
        autoWhiteBalance: false,
        kelvin: recipe.kelvin!.clamp(c.kelvinMin, c.kelvinMax),
      );
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

class ProCameraLastPhoto {
  const ProCameraLastPhoto({required this.uri, this.thumb});

  final String uri;
  final Uint8List? thumb;
}

/// Talks to the native camera (Android, ProCameraPlugin.kt).
///
/// [values] holds the live settings: widgets listen to it directly, so a
/// moving dial does not rebuild the preview. Changes reach the camera at
/// most every 33 ms, always ending with the latest value.
class ProCameraController extends ChangeNotifier {
  ProCameraController({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('shotbook/pro_camera');

  final MethodChannel _channel;

  ProCameraCapabilities capabilities = const ProCameraCapabilities(
    available: false,
  );
  final values = ValueNotifier(const ProCameraSettings());
  int? textureId;
  int previewWidth = 4;
  int previewHeight = 3;
  bool rawAvailable = false;
  bool busy = false;

  Timer? _sendTimer;
  bool _sending = false;
  bool _dirty = false;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  ProCameraSettings get settings => values.value;

  /// Preview aspect ratio in portrait (width / height).
  double get portraitAspectRatio =>
      math.min(previewWidth, previewHeight) /
      math.max(previewWidth, previewHeight);

  Future<bool> loadCapabilities() async {
    try {
      final map = await _channel
          .invokeMapMethod<Object?, Object?>('capabilities')
          // A phone that never answers gets the basic camera.
          .timeout(const Duration(seconds: 3));
      capabilities = ProCameraCapabilities.fromMap(map ?? const {});
    } on MissingPluginException {
      capabilities = const ProCameraCapabilities(available: false);
    } on TimeoutException {
      capabilities = const ProCameraCapabilities(available: false);
    } on PlatformException {
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
    if (!rawAvailable && settings.raw) {
      values.value = settings.copyWith(raw: false);
    }
    _dirty = true;
    await _flush();
    notifyListeners();
  }

  /// Shows [next] at once and sends it to the camera soon.
  void update(ProCameraSettings next) {
    values.value = next;
    _dirty = true;
    if (_sending || _sendTimer != null) return;
    final wait = 33 - DateTime.now().difference(_lastSent).inMilliseconds;
    _sendTimer = Timer(Duration(milliseconds: wait.clamp(0, 33)), () {
      _sendTimer = null;
      _flush();
    });
  }

  Future<void> _flush() async {
    if (textureId == null || !_dirty) return;
    _dirty = false;
    _sending = true;
    final s = settings;
    final c = capabilities;
    try {
      await _channel.invokeMethod<void>('setControls', {
        'autoExposure': s.autoExposure || !c.manualSensor,
        'iso': s.iso,
        'exposureNs': s.exposureNs,
        'ev': c.exposureCompensation ? (s.ev / c.evStep).round() : 0,
        'awbAuto': s.autoWhiteBalance,
        'kelvin': s.kelvin,
        'autoFocus': s.autoFocus || !c.manualFocus,
        'focusDiopters': s.focusDiopters,
        'zoom': s.zoom,
        'flash': c.flash ? s.flash : 'off',
      });
    } on PlatformException {
      // The preview keeps the last settings the camera accepted.
    } finally {
      _sending = false;
      _lastSent = DateTime.now();
    }
    // Something changed while sending: send the latest once more.
    if (_dirty) update(settings);
  }

  Future<ProCameraPhotoResult> capture() async {
    busy = true;
    notifyListeners();
    try {
      final look = settings.look;
      final map = await _channel.invokeMapMethod<Object?, Object?>('capture', {
        'raw': settings.raw && rawAvailable,
        // The look is baked into the JPEG on the phone; RAW stays clean.
        if (!look.isNone) ...{
          'colorMatrix': look.colorMatrix,
          'vignette': look.vignette,
          'grain': look.grain,
        },
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

  /// The newest SHOTBOOK photo in the gallery (uri + small JPEG thumbnail).
  Future<ProCameraLastPhoto?> lastPhoto() async {
    try {
      final map = await _channel
          .invokeMapMethod<Object?, Object?>('lastPhoto')
          .timeout(const Duration(seconds: 3));
      final uri = map?['uri'] as String?;
      if (uri == null) return null;
      return ProCameraLastPhoto(uri: uri, thumb: map?['thumb'] as Uint8List?);
    } on Object {
      return null;
    }
  }

  /// Opens [uri] (or the gallery when null) in the phone's gallery app.
  Future<bool> openPhoto(String? uri) async {
    try {
      await _channel.invokeMethod<void>('openPhoto', {'uri': uri});
      return true;
    } on Object {
      return false;
    }
  }

  /// Raw report from the native camera; null where unsupported.
  Future<Map<Object?, Object?>?> diagnostics() async {
    try {
      return await _channel.invokeMapMethod<Object?, Object?>('diagnostics');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<void> close() async {
    _sendTimer?.cancel();
    _sendTimer = null;
    textureId = null;
    try {
      await _channel.invokeMethod<void>('close');
    } on MissingPluginException {
      // Nothing to close on platforms without the native camera.
    }
  }

  @override
  void dispose() {
    _sendTimer?.cancel();
    values.dispose();
    super.dispose();
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

T _nearestLog<T extends num>(List<T> stops, num value) {
  var best = stops.first;
  for (final s in stops) {
    if ((math.log(s) - math.log(value)).abs() <
        (math.log(best) - math.log(value)).abs()) {
      best = s;
    }
  }
  return best;
}

/// Standard 1/3-stop shutter speeds between [minNs] and [maxNs].
List<int> shutterStops(int minNs, int maxNs) {
  const denominators = [
    8000, 6400, 5000, 4000, 3200, 2500, 2000, 1600, 1250, 1000, 800, 640, //
    500, 400, 320, 250, 200, 160, 125, 100, 80, 60, 50, 40, 30, 25, 20, 15,
    13, 10, 8, 6, 5, 4, 3,
  ];
  final all = [
    for (final d in denominators) (1e9 / d).round(),
    for (final s in const [0.4, 0.5, 0.6, 0.8, 1.0]) (s * 1e9).round(),
  ];
  final inRange = [
    for (final ns in all)
      if (ns >= minNs && ns <= maxNs) ns,
  ];
  return inRange.isEmpty ? [minNs, maxNs] : inRange;
}

/// Standard 1/3-stop ISO values between [min] and [max].
List<int> isoStops(int min, int max) {
  const all = [
    25, 32, 40, 50, 64, 80, 100, 125, 160, 200, 250, 320, 400, 500, 640, //
    800, 1000, 1250, 1600, 2000, 2500, 3200, 4000, 5000, 6400, 8000, 10000,
    12800,
  ];
  final inRange = [
    for (final iso in all)
      if (iso >= min && iso <= max) iso,
  ];
  return inRange.isEmpty ? [min, max] : inRange;
}

int nearestStop(List<int> stops, num value) => _nearestLog(stops, value);

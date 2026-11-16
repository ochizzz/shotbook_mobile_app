import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/theme.dart';
import '../../l10n/tr.dart';
import '../../shared/widgets/photo_reference_image.dart';
import '../discover/domain/photo_reference.dart';
import 'camera_diagnostics.dart';
import 'camera_recipe.dart';
import 'photo_look.dart';
import 'pro_camera_controller.dart';
import 'widgets/ruler_dial.dart';
import 'widgets/zoom_control.dart';

enum _Dial { iso, shutter, ev, wb, focus, look }

const _accent = ShotbookColors.accent;
const _timers = [0, 3, 10];
const _flashModes = ['off', 'auto', 'on'];

/// SHOTBOOK's manual photo camera, laid out like the iPhone and Pixel
/// cameras: flash and timer top left, options top right, zoom over the
/// preview, settings row with spinning dials, exit bottom left.
///
/// With a [photo] it shows the reference as a see-through guide and can
/// apply the photo's settings; without one it is the plain Camera tab.
class ProCameraView extends StatefulWidget {
  const ProCameraView({
    required this.fallback,
    this.photo,
    this.onOpened,
    super.key,
  });

  final PhotoReference? photo;
  final WidgetBuilder fallback;

  /// Called once when the camera opens (counts as using the photo).
  final VoidCallback? onOpened;

  @override
  State<ProCameraView> createState() => _ProCameraViewState();
}

class _ProCameraViewState extends State<ProCameraView>
    with WidgetsBindingObserver {
  final _camera = ProCameraController();
  final _dial = ValueNotifier<_Dial?>(null);
  bool _ready = false;
  bool _unsupported = false;
  String? _error;
  double _opacity = 0.4;
  String _lookParam = 'contrast';
  bool _showGuide = true;
  bool _grid = true;
  bool _flashBlink = false;
  int _timer = 0;
  int? _countdown;
  Timer? _countdownTimer;
  ProCameraLastPhoto? _lastShot;

  PhotoReference? get _photo => widget.photo;
  ProCameraCapabilities get _caps => _camera.capabilities;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camera.addListener(_onCamera);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _camera.removeListener(_onCamera);
    _camera.close();
    _camera.dispose();
    _dial.dispose();
    super.dispose();
  }

  void _onCamera() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cancelCountdown();
      _camera.close();
    } else if (state == AppLifecycleState.resumed) {
      _open();
    }
  }

  Future<void> _start() async {
    if (!await _camera.loadCapabilities()) {
      // The basic camera takes over and reports the use itself.
      if (mounted) setState(() => _unsupported = true);
      return;
    }
    widget.onOpened?.call();
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(
          () => _error =
              'Allow camera access in your phone settings to repeat a shot.',
        );
      }
      return;
    }
    await _open();
  }

  Future<void> _open() async {
    try {
      await _camera.open();
      if (mounted) setState(() => _ready = true);
      unawaited(_refreshLastShot());
    } on PlatformException {
      if (mounted) setState(() => _error = 'The camera could not be started.');
    }
  }

  void _set(ProCameraSettings next) => _camera.update(next);

  Future<void> _refreshLastShot() async {
    final last = await _camera.lastPhoto();
    if (mounted && last != null) setState(() => _lastShot = last);
  }

  Future<void> _openGallery() async {
    HapticFeedback.selectionClick();
    final failText = context.tr('Could not open the gallery.');
    if (!await _camera.openPhoto(_lastShot?.uri) && mounted) _snack(failText);
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          // Above the shutter row, never over the controls.
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
          content: Text(text),
        ),
      );
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    _set(_camera.settings.reset());
    _dial.value = null;
  }

  void _applyRecipe() {
    final photo = _photo;
    if (photo == null || !_ready) return;
    final recipe = CameraRecipe.fromPhoto(
      photo,
      mainEquivalentMm: _caps.mainEquivalentMm,
    );
    final look = lookFromPhoto(photo);
    HapticFeedback.mediumImpact();
    final next = _camera.settings.withRecipe(recipe, _caps, look: look);
    _set(next);
    _snack(_recipeSummary(recipe, next, look));
  }

  /// What "Apply photo settings" actually set, so nothing is a surprise.
  String _recipeSummary(
    CameraRecipe recipe,
    ProCameraSettings s,
    PhotoLook look,
  ) {
    final parts = <String>[];
    if (recipe.zoom != null) {
      parts.add(
        _caps.zoomable
            ? '${_trimZoom(s.zoom)}×'
            : context.tr('zoom unavailable on this phone'),
      );
    }
    if (!s.autoExposure && _caps.manualSensor) {
      parts.add('ISO ${s.iso} · ${formatShutter(s.exposureNs)}');
    } else if (s.ev != 0) {
      parts.add('${_signed(s.ev)} EV');
    }
    if (!s.autoWhiteBalance) parts.add('${s.kelvin}K');
    if (!look.isNone) {
      final traits = <String>[
        if (look.mono) context.tr('B&W'),
        if (look.warmth > 0.05) context.tr('warmer'),
        if (look.warmth < -0.05) context.tr('cooler'),
        if (look.contrast > 0.05) context.tr('more contrast'),
        if (look.contrast < -0.05) context.tr('softer'),
        if (look.fade > 0.05) context.tr('matte'),
        if (look.vignette > 0.05) context.tr('vignette'),
        if (look.grain > 0.05) context.tr('grain'),
      ];
      parts.add(
        context.tr('filter: {traits}', {
          'traits': traits.isEmpty ? context.tr('subtle') : traits.join(', '),
        }),
      );
    }
    if (parts.isEmpty) {
      return context.tr(
        'This photo has no fixed settings: the camera stays on auto.',
      );
    }
    return context.tr('Applied: {list}', {'list': parts.join(' · ')});
  }

  static String _trimZoom(double z) =>
      z == z.roundToDouble() ? z.toStringAsFixed(0) : z.toStringAsFixed(1);

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_countdown != null && mounted) setState(() => _countdown = null);
  }

  void _onShutter() {
    if (_camera.busy || !_ready) return;
    if (_countdown != null) {
      _cancelCountdown();
      return;
    }
    if (_timer == 0) {
      _shoot();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _countdown = _timer);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = (_countdown ?? 1) - 1;
      if (next <= 0) {
        t.cancel();
        _countdownTimer = null;
        setState(() => _countdown = null);
        _shoot();
      } else {
        HapticFeedback.selectionClick();
        setState(() => _countdown = next);
      }
    });
  }

  Future<void> _shoot() async {
    HapticFeedback.lightImpact();
    setState(() => _flashBlink = true);
    Future.delayed(const Duration(milliseconds: 110), () {
      if (mounted) setState(() => _flashBlink = false);
    });
    final rawText = context.tr(
      'Saved to SHOTBOOK in your gallery: JPEG + RAW.',
    );
    final jpegText = context.tr('Saved to SHOTBOOK in your gallery.');
    final failText = context.tr('The photo could not be saved.');
    try {
      final result = await _camera.capture();
      if (mounted) _snack(result.dng != null ? rawText : jpegText);
      unawaited(_refreshLastShot());
    } on PlatformException {
      if (mounted) _snack(failText);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unsupported) return widget.fallback(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: const Key('pro-camera'),
        backgroundColor: ShotbookColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(context),
              // Full-width preview right under the top bar (as on the
              // iPhone), settings directly below it, shutter row at the
              // bottom. The preview shrinks only on short screens.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => ValueListenableBuilder<_Dial?>(
                    valueListenable: _dial,
                    builder: (context, open, _) {
                      final ratio = _ready
                          ? _camera.portraitAspectRatio
                          : 3 / 4;
                      // Room for the settings row and the open panel (the
                      // filter panel is taller than a single dial).
                      final panel = open == _Dial.look ? 112.0 : 44.0;
                      final maxH = box.maxHeight - 44 - panel;
                      final h = (box.maxWidth / ratio).clamp(0.0, maxH);
                      return Column(
                        children: [
                          SizedBox(
                            width: h * ratio,
                            height: h,
                            child: Center(child: _preview(context)),
                          ),
                          _ValueBuilder(
                            camera: _camera,
                            dial: _dial,
                            builder: (context, s, dial) =>
                                _readouts(context, s, dial),
                          ),
                          _ValueBuilder(
                            camera: _camera,
                            dial: _dial,
                            builder: (context, s, dial) => AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: dial == null
                                  ? const SizedBox(width: double.infinity)
                                  : _dialPanel(context, s, dial),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              _bottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Top bar --------------------------------------------------------

  Widget _icon(
    IconData icon,
    VoidCallback? onTap, {
    required String tooltip,
    Key? key,
    bool active = false,
    String? badge,
  }) {
    final color = onTap == null
        ? Colors.white24
        : active
        ? _accent
        : Colors.white;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        key: key,
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 21, color: color),
              if (badge != null)
                Positioned(
                  right: 2,
                  bottom: 4,
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ValueListenableBuilder<ProCameraSettings>(
          valueListenable: _camera.values,
          builder: (context, s, _) {
            final rawEnabled = _camera.rawAvailable;
            final rawOn = s.raw && rawEnabled;
            final flashIcon = switch (s.flash) {
              'auto' => Icons.flash_auto,
              'on' => Icons.flash_on,
              _ => Icons.flash_off,
            };
            return Row(
              children: [
                _icon(
                  flashIcon,
                  _caps.flash
                      ? () {
                          HapticFeedback.selectionClick();
                          final i = _flashModes.indexOf(s.flash);
                          _set(
                            s.copyWith(
                              flash: _flashModes[(i + 1) % _flashModes.length],
                            ),
                          );
                        }
                      : null,
                  tooltip: context.tr('Flash'),
                  key: const Key('pro-flash'),
                  active: s.flash != 'off',
                ),
                _icon(
                  _timer == 0 ? Icons.timer_off_outlined : Icons.timer_outlined,
                  () {
                    HapticFeedback.selectionClick();
                    setState(
                      () => _timer =
                          _timers[(_timers.indexOf(_timer) + 1) %
                              _timers.length],
                    );
                  },
                  tooltip: context.tr('Timer'),
                  key: const Key('pro-timer'),
                  active: _timer > 0,
                  badge: _timer == 0 ? null : '$_timer',
                ),
                const Spacer(),
                Tooltip(
                  message: rawEnabled
                      ? context.tr('Also save RAW (DNG)')
                      : context.tr(
                          'This phone does not give RAW to other apps',
                        ),
                  child: GestureDetector(
                    key: const Key('pro-raw'),
                    onTap: rawEnabled
                        ? () {
                            HapticFeedback.selectionClick();
                            _set(s.copyWith(raw: !s.raw));
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: shotbookTagRadius,
                        color: rawOn ? _accent : Colors.transparent,
                        border: Border.all(
                          width: 1.2,
                          color: rawEnabled
                              ? (rawOn ? _accent : Colors.white)
                              : Colors.white24,
                        ),
                      ),
                      child: Text(
                        'RAW',
                        style: TextStyle(
                          fontFamily: shotbookMonoFont,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.8,
                          color: rawOn
                              ? Colors.black
                              : rawEnabled
                              ? Colors.white
                              : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _icon(
                  Icons.grid_3x3,
                  () => setState(() => _grid = !_grid),
                  tooltip: context.tr('Grid'),
                  key: const Key('pro-grid'),
                  active: _grid,
                ),
                if (_photo != null)
                  _icon(
                    _showGuide ? Icons.layers : Icons.layers_clear_outlined,
                    () => setState(() => _showGuide = !_showGuide),
                    tooltip: _showGuide
                        ? context.tr('Hide guide')
                        : context.tr('Show guide'),
                    key: const Key('pro-guide'),
                    active: _showGuide,
                  ),
                _icon(
                  Icons.info_outline,
                  () => showCameraDiagnostics(context, _camera),
                  tooltip: context.tr('Camera diagnostics'),
                  key: const Key('pro-diagnostics'),
                ),
                _icon(
                  Icons.restart_alt,
                  s.isDefault ? null : _reset,
                  tooltip: context.tr('Reset to auto'),
                  key: const Key('pro-reset'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---- Preview --------------------------------------------------------

  Widget _preview(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          context.tr(_error!),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
      );
    }
    final id = _camera.textureId;
    if (!_ready || id == null) {
      return const CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white38,
      );
    }
    final photo = _photo;
    return AspectRatio(
      aspectRatio: _camera.portraitAspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The look is shown live: a colour matrix over the camera image
          // plus a vignette; the saved JPEG gets the same processing.
          ValueListenableBuilder<ProCameraSettings>(
            valueListenable: _camera.values,
            builder: (context, s, child) {
              final look = s.look;
              if (look.isNone) return child!;
              return Stack(
                fit: StackFit.expand,
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(look.colorMatrix),
                    child: child,
                  ),
                  if (look.vignette > 0)
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            radius: 0.85,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withValues(
                                alpha: (look.vignette * 0.78).clamp(0.0, 1.0),
                              ),
                            ],
                            stops: const [0, 0.55, 1],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            child: RepaintBoundary(child: Texture(textureId: id)),
          ),
          if (photo != null && _showGuide)
            IgnorePointer(
              child: Opacity(
                opacity: _opacity,
                child: PhotoReferenceImage(photo: photo),
              ),
            ),
          if (_grid) const IgnorePointer(child: CustomPaint(painter: _Grid())),
          if (photo != null && _showGuide)
            Positioned(
              right: 2,
              top: 56,
              bottom: 96,
              child: _OpacitySlider(
                value: _opacity,
                onChanged: (v) => setState(() => _opacity = v),
              ),
            ),
          if (_caps.zoomable)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<ProCameraSettings>(
                valueListenable: _camera.values,
                builder: (context, s, _) => ZoomControl(
                  zoom: s.zoom,
                  min: _caps.zoomMin,
                  max: _caps.zoomMax,
                  onChanged: (z) => _set(_camera.settings.copyWith(zoom: z)),
                ),
              ),
            ),
          if (_countdown != null)
            IgnorePointer(
              child: Center(
                child: Text(
                  '$_countdown',
                  key: const Key('pro-countdown'),
                  style: const TextStyle(
                    fontFamily: shotbookTitleFont,
                    fontSize: 88,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 12)],
                  ),
                ),
              ),
            ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _flashBlink ? 0.65 : 0,
              duration: const Duration(milliseconds: 80),
              child: const ColoredBox(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Settings row and dials ----------------------------------------

  bool _enabled(_Dial dial) => switch (dial) {
    _Dial.iso || _Dial.shutter => _caps.manualSensor,
    _Dial.ev => _caps.exposureCompensation,
    _Dial.wb => true,
    _Dial.focus => _caps.manualFocus,
    _Dial.look => true,
  };

  bool _isAuto(_Dial dial, ProCameraSettings s) => switch (dial) {
    _Dial.iso || _Dial.shutter => s.autoExposure || !_caps.manualSensor,
    _Dial.ev => s.ev == 0,
    _Dial.wb => s.autoWhiteBalance,
    _Dial.focus => s.autoFocus || !_caps.manualFocus,
    _Dial.look => s.look.isNone,
  };

  String _readout(_Dial dial, ProCameraSettings s) {
    final manual = _caps.manualSensor && !s.autoExposure;
    return switch (dial) {
      _Dial.iso => manual ? '${s.iso}' : 'AUTO',
      _Dial.shutter => manual ? formatShutter(s.exposureNs) : 'AUTO',
      _Dial.ev => manual ? '—' : _signed(s.ev),
      _Dial.wb => s.autoWhiteBalance ? 'AWB' : '${s.kelvin}K',
      _Dial.focus => s.autoFocus || !_caps.manualFocus ? 'AF' : 'MF',
      _Dial.look =>
        s.look.isNone ? '—' : context.tr(lookNames[s.look.id] ?? 'Custom'),
    };
  }

  /// Back to automatic for one setting (double tap on its readout).
  ProCameraSettings _autoFor(_Dial dial, ProCameraSettings s) => switch (dial) {
    _Dial.iso || _Dial.shutter => s.copyWith(autoExposure: true),
    _Dial.ev => s.copyWith(ev: 0),
    _Dial.wb => s.copyWith(autoWhiteBalance: true),
    _Dial.focus => s.copyWith(autoFocus: true),
    _Dial.look => s.copyWith(look: PhotoLook.none),
  };

  Widget _readouts(BuildContext context, ProCameraSettings s, _Dial? open) {
    final labels = {
      _Dial.iso: 'ISO',
      _Dial.shutter: context.tr('SHUTTER'),
      _Dial.ev: 'EV',
      _Dial.wb: context.tr('WB'),
      _Dial.focus: context.tr('FOCUS'),
      _Dial.look: context.tr('FILTER'),
    };
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          for (final dial in _Dial.values)
            Expanded(
              child: GestureDetector(
                key: Key('pro-cell-${dial.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: _enabled(dial)
                    ? () {
                        HapticFeedback.selectionClick();
                        _dial.value = open == dial ? null : dial;
                      }
                    : null,
                onDoubleTap: _enabled(dial)
                    ? () {
                        HapticFeedback.mediumImpact();
                        _set(_autoFor(dial, _camera.settings));
                      }
                    : null,
                child: _Readout(
                  label: labels[dial]!,
                  value: _readout(dial, s),
                  selected: open == dial,
                  manual: !_isAuto(dial, s),
                  enabled: _enabled(dial),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dialPanel(BuildContext context, ProCameraSettings s, _Dial dial) {
    if (dial == _Dial.look) return _lookPanel(context, s);
    Widget? lead;
    late Widget ruler;
    switch (dial) {
      case _Dial.iso:
        final stops = isoStops(_caps.isoMin, _caps.isoMax);
        final index = stops.indexOf(nearestStop(stops, s.iso));
        lead = _autoPill(
          s.autoExposure,
          () => _set(_camera.settings.copyWith(autoExposure: true)),
        );
        ruler = RulerDial(
          key: const Key('pro-dial-iso'),
          value: stops.length > 1 ? index / (stops.length - 1) : 0,
          divisions: stops.length - 1,
          startLabel: '${stops.first}',
          endLabel: '${stops.last}',
          onChanged: (t) => _set(
            _camera.settings.copyWith(
              autoExposure: false,
              iso: stops[(t * (stops.length - 1)).round()],
            ),
          ),
        );
      case _Dial.shutter:
        final stops = shutterStops(_caps.exposureMinNs, _caps.exposureMaxNs);
        final index = stops.indexOf(nearestStop(stops, s.exposureNs));
        lead = _autoPill(
          s.autoExposure,
          () => _set(_camera.settings.copyWith(autoExposure: true)),
        );
        // Left = fast, right = slow, as on a shutter dial.
        ruler = RulerDial(
          key: const Key('pro-dial-shutter'),
          value: stops.length > 1 ? index / (stops.length - 1) : 0,
          divisions: stops.length - 1,
          startLabel: formatShutter(stops.first),
          endLabel: formatShutter(stops.last),
          onChanged: (t) => _set(
            _camera.settings.copyWith(
              autoExposure: false,
              exposureNs: stops[(t * (stops.length - 1)).round()],
            ),
          ),
        );
      case _Dial.ev:
        final enabled = !(_caps.manualSensor && !s.autoExposure);
        final span = _caps.evMax - _caps.evMin;
        final step = ((s.ev / _caps.evStep).round() - _caps.evMin).clamp(
          0,
          span,
        );
        ruler = RulerDial(
          key: const Key('pro-dial-ev'),
          enabled: enabled,
          value: span > 0 ? step / span : 0.5,
          divisions: span,
          majorEvery: (1 / _caps.evStep).round().clamp(1, 12),
          startLabel: _signed(_caps.evMin * _caps.evStep),
          endLabel: _signed(_caps.evMax * _caps.evStep),
          onChanged: (t) => _set(
            _camera.settings.copyWith(
              ev: ((t * span).round() + _caps.evMin) * _caps.evStep,
            ),
          ),
        );
        if (!enabled) {
          lead = _hint(
            context.tr(
              'Exposure compensation works with automatic ISO and shutter.',
            ),
          );
        }
      case _Dial.wb:
        // 2000–10000 K in 100 K steps.
        final min = _caps.kelvinMin;
        final steps = (_caps.kelvinMax - min) ~/ 100;
        lead = _autoPill(
          s.autoWhiteBalance,
          () => _set(_camera.settings.copyWith(autoWhiteBalance: true)),
          label: 'AWB',
        );
        ruler = RulerDial(
          key: const Key('pro-dial-wb'),
          value: steps > 0 ? (s.kelvin - min) / 100 / steps : 0,
          divisions: steps,
          majorEvery: 10,
          startLabel: '${min}K',
          endLabel: '${_caps.kelvinMax}K',
          onChanged: (t) => _set(
            _camera.settings.copyWith(
              autoWhiteBalance: false,
              kelvin: min + (t * steps).round() * 100,
            ),
          ),
        );
      case _Dial.look:
        throw StateError('handled by _lookPanel');
      case _Dial.focus:
        lead = _autoPill(
          s.autoFocus,
          () => _set(_camera.settings.copyWith(autoFocus: true)),
          label: 'AF',
        );
        ruler = RulerDial(
          key: const Key('pro-dial-focus'),
          value: _caps.minFocusDiopters > 0
              ? (s.focusDiopters / _caps.minFocusDiopters).clamp(0.0, 1.0)
              : 0,
          startLabel: '∞',
          endLabel: context.tr('near'),
          onChanged: (t) => _set(
            _camera.settings.copyWith(
              autoFocus: false,
              focusDiopters: t * _caps.minFocusDiopters,
            ),
          ),
        );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Row(
        children: [
          ?lead,
          if (lead != null) const SizedBox(width: 6),
          Expanded(child: SizedBox(height: 40, child: ruler)),
        ],
      ),
    );
  }

  /// Filter panel: ready-made looks, then fine sliders for each trait.
  Widget _lookPanel(BuildContext context, ProCameraSettings s) {
    final look = s.look;
    final photo = _photo;
    final presets = <PhotoLook>[
      ...lookPresets.take(1),
      if (photo != null) lookFromPhoto(photo),
      ...lookPresets.skip(1),
    ];
    // (id, label, min, value)
    final params = <(String, String, double, double)>[
      ('contrast', context.tr('Contrast'), -1, look.contrast),
      ('saturation', context.tr('Saturation'), -1, look.saturation),
      ('warmth', context.tr('Warmth'), -1, look.warmth),
      ('tint', context.tr('Tint'), -1, look.tint),
      ('shadows', context.tr('Shadows'), -1, look.shadows),
      ('highlights', context.tr('Highlights'), -1, look.highlights),
      ('fade', context.tr('Fade'), 0, look.fade),
      ('vignette', context.tr('Vignette'), 0, look.vignette),
      ('grain', context.tr('Grain'), 0, look.grain),
    ];
    final param = params.firstWhere(
      (p) => p.$1 == _lookParam,
      orElse: () => params.first,
    );
    PhotoLook changed(double v) => switch (param.$1) {
      'contrast' => look.copyWith(id: 'custom', contrast: v),
      'saturation' => look.copyWith(id: 'custom', saturation: v),
      'warmth' => look.copyWith(id: 'custom', warmth: v),
      'tint' => look.copyWith(id: 'custom', tint: v),
      'shadows' => look.copyWith(id: 'custom', shadows: v),
      'highlights' => look.copyWith(id: 'custom', highlights: v),
      'fade' => look.copyWith(id: 'custom', fade: v),
      'vignette' => look.copyWith(id: 'custom', vignette: v),
      _ => look.copyWith(id: 'custom', grain: v),
    };
    Widget pill(String label, bool active, VoidCallback onTap, {Key? key}) =>
        GestureDetector(
          key: key,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: shotbookBorderRadius,
              color: active ? _accent : Colors.transparent,
              border: Border.all(color: active ? _accent : Colors.white24),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? ShotbookColors.background : Colors.white,
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final preset in presets)
                  pill(
                    context.tr(lookNames[preset.id] ?? 'Custom'),
                    look.id == preset.id,
                    () => _set(_camera.settings.copyWith(look: preset)),
                    key: Key('look-${preset.id}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 22,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                GestureDetector(
                  key: const Key('look-mono-toggle'),
                  onTap: () => _set(
                    _camera.settings.copyWith(
                      look: look.copyWith(id: 'custom', mono: !look.mono),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Text(
                      context.tr('B&W'),
                      style: TextStyle(
                        fontFamily: shotbookMonoFont,
                        fontSize: 11,
                        color: look.mono ? _accent : Colors.white54,
                      ),
                    ),
                  ),
                ),
                for (final p in params)
                  GestureDetector(
                    key: Key('look-param-${p.$1}'),
                    onTap: () => setState(() => _lookParam = p.$1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Text(
                        p.$2.toUpperCase(),
                        style: TextStyle(
                          fontFamily: shotbookMonoFont,
                          fontSize: 11,
                          color: p.$1 == param.$1
                              ? _accent
                              : p.$4 != 0
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: RulerDial(
              key: Key('pro-dial-look-${param.$1}'),
              value: param.$3 < 0 ? (param.$4 + 1) / 2 : param.$4,
              divisions: param.$3 < 0 ? 40 : 20,
              majorEvery: 5,
              startLabel: param.$3 < 0 ? '−100' : '0',
              endLabel: '+100',
              onChanged: (t) => _set(
                _camera.settings.copyWith(
                  look: changed(param.$3 < 0 ? t * 2 - 1 : t),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoPill(bool active, VoidCallback onTap, {String label = 'AUTO'}) {
    return GestureDetector(
      key: Key('pro-auto-${_dial.value?.name}'),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: shotbookTagRadius,
          color: active ? _accent : Colors.transparent,
          border: Border.all(color: active ? _accent : Colors.white38),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: shotbookMonoFont,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: active ? ShotbookColors.background : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _hint(String text) => SizedBox(
    width: 110,
    child: Text(
      text,
      style: const TextStyle(fontSize: 9.5, color: Colors.white54),
    ),
  );

  // ---- Bottom bar -----------------------------------------------------

  Widget _bottomBar(BuildContext context) {
    final photo = _photo;
    return SizedBox(
      height: 96,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _roundButton(
                      key: const Key('pro-close'),
                      tooltip: context.tr('Close'),
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _galleryButton(context),
                  ],
                ),
              ),
            ),
            GestureDetector(
              key: const Key('pro-shutter'),
              onTap: _onShutter,
              child: AnimatedScale(
                scale: _camera.busy ? 0.9 : 1,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: Container(
                  width: 70,
                  height: 70,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _countdown != null ? _accent : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: photo == null
                    ? const SizedBox(width: 44)
                    : _roundButton(
                        key: const Key('pro-apply-recipe'),
                        tooltip: context.tr('Apply photo settings'),
                        onTap: _ready ? _applyRecipe : null,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PhotoReferenceImage(photo: photo, thumbnail: true),
                            Container(color: Colors.black38),
                            const Icon(
                              Icons.auto_fix_high,
                              color: _accent,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Last shot as a small rounded square (as on the iPhone); opens it in
  /// the gallery app. A gallery icon until the first shot.
  Widget _galleryButton(BuildContext context) {
    final thumb = _lastShot?.thumb;
    return Tooltip(
      message: context.tr('Gallery'),
      child: GestureDetector(
        key: const Key('pro-gallery'),
        onTap: _openGallery,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Container(
            key: ValueKey(_lastShot?.uri),
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: shotbookBorderRadius,
              border: Border.all(color: Colors.white24),
            ),
            child: thumb == null
                ? const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 20,
                  )
                : Image.memory(thumb, fit: BoxFit.cover, gaplessPlayback: true),
          ),
        ),
      ),
    );
  }

  Widget _roundButton({
    required Widget child,
    required String tooltip,
    required VoidCallback? onTap,
    Key? key,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        key: key,
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.12),
          ),
          child: child,
        ),
      ),
    );
  }

  static String _signed(double v) => v.abs() < 0.05
      ? '±0'
      : '${v > 0 ? '+' : '−'}${v.abs().toStringAsFixed(1)}';
}

/// Rebuilds only its child when the settings or the open dial change.
class _ValueBuilder extends StatelessWidget {
  const _ValueBuilder({
    required this.camera,
    required this.dial,
    required this.builder,
  });

  final ProCameraController camera;
  final ValueNotifier<_Dial?> dial;
  final Widget Function(BuildContext, ProCameraSettings, _Dial?) builder;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_Dial?>(
      valueListenable: dial,
      builder: (context, open, _) => ValueListenableBuilder<ProCameraSettings>(
        valueListenable: camera.values,
        builder: (context, s, _) => builder(context, s, open),
      ),
    );
  }
}

class _Readout extends StatelessWidget {
  const _Readout({
    required this.label,
    required this.value,
    required this.selected,
    required this.manual,
    required this.enabled,
  });

  final String label;
  final String value;
  final bool selected;
  final bool manual;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.white24
        : selected
        ? _accent
        : manual
        ? Colors.white
        : Colors.white70;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: shotbookMonoFont,
            fontSize: 9,
            letterSpacing: 0.6,
            color: enabled
                ? (selected ? _accent : Colors.white38)
                : Colors.white24,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            fontFamily: shotbookMonoFont,
            fontSize: 13.5,
            fontWeight: manual ? FontWeight.w700 : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
            color: color,
          ),
          // One line always: long names (filters) shrink instead of wrapping.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, softWrap: false),
          ),
        ),
      ],
    );
  }
}

/// Vertical see-through-guide slider on the preview's edge.
class _OpacitySlider extends StatelessWidget {
  const _OpacitySlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            key: const Key('pro-guide-opacity'),
            value: value,
            min: 0.1,
            max: 0.9,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _Grid extends CustomPainter {
  const _Grid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 0.5;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Grid oldDelegate) => false;
}

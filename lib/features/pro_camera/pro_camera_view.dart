import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/tr.dart';
import '../../shared/widgets/photo_reference_image.dart';
import '../discover/domain/photo_reference.dart';
import 'camera_recipe.dart';
import 'pro_camera_controller.dart';
import 'widgets/ruler_dial.dart';
import 'widgets/zoom_control.dart';

enum _Dial { iso, shutter, ev, wb, focus }

const _accent = Color(0xFFFFD25A);

const _wbOrder = [
  'auto',
  'incandescent',
  'fluorescent',
  'daylight',
  'cloudy',
  'shade',
];
const _wbKelvin = {
  'incandescent': '3200K',
  'fluorescent': '4000K',
  'daylight': '5500K',
  'cloudy': '6500K',
  'shade': '7500K',
};

/// Whole stops between two values, for 1/3-stop snapping on the dials.
double _stops(num min, num max) =>
    max > min ? math.log(max / min) / math.ln2 : 0;

/// SHOTBOOK's manual photo camera. With a [photo] it shows the reference as
/// a see-through guide and can apply the photo's settings; without one it
/// is a plain pro camera (the Camera tab).
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
  bool _ready = false;
  bool _unsupported = false;
  String? _error;
  _Dial? _dial;
  double _opacity = 0.4;
  bool _showGuide = true;
  bool _grid = true;
  bool _flash = false;
  Timer? _pushTimer;
  ProCameraSettings? _pending;

  PhotoReference? get _photo => widget.photo;

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
    _pushTimer?.cancel();
    _camera.removeListener(_onCamera);
    _camera.close();
    _camera.dispose();
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
    } on PlatformException {
      if (mounted) setState(() => _error = 'The camera could not be started.');
    }
  }

  /// Dials fire many changes per second: show each at once, send them to
  /// the camera at most every 40 ms.
  void _set(ProCameraSettings next) {
    _camera.settings = next;
    setState(() {});
    _pending = next;
    _pushTimer ??= Timer(const Duration(milliseconds: 40), () async {
      _pushTimer = null;
      final value = _pending;
      _pending = null;
      if (value == null) return;
      try {
        await _camera.update(value);
      } on PlatformException {
        // The preview keeps the last settings the camera accepted.
      }
    });
  }

  void _applyRecipe() {
    final photo = _photo;
    if (photo == null) return;
    final caps = _camera.capabilities;
    final recipe = CameraRecipe.fromPhoto(
      photo,
      mainEquivalentMm: caps.mainEquivalentMm,
    );
    HapticFeedback.mediumImpact();
    _set(_camera.settings.withRecipe(recipe, caps));
    final manual =
        caps.manualSensor && recipe.iso != null && recipe.exposureNs != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          recipe.isEmpty
              ? context.tr(
                  'This photo has no fixed settings: the camera stays on auto.',
                )
              : manual
              ? context.tr('Settings from the photo applied.')
              : context.tr(
                  'Settings applied. ISO and shutter stay automatic on this phone or recipe.',
                ),
        ),
      ),
    );
  }

  Future<void> _shoot() async {
    if (_camera.busy || !_ready) return;
    HapticFeedback.lightImpact();
    setState(() => _flash = true);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _flash = false);
    });
    final messenger = ScaffoldMessenger.of(context);
    final rawText = context.tr(
      'Saved to SHOTBOOK in your gallery: JPEG + RAW.',
    );
    final jpegText = context.tr('Saved to SHOTBOOK in your gallery.');
    final failText = context.tr('The photo could not be saved.');
    try {
      final result = await _camera.capture();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(result.dng != null ? rawText : jpegText),
        ),
      );
    } on PlatformException {
      messenger.showSnackBar(SnackBar(content: Text(failText)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unsupported) return widget.fallback(context);
    final caps = _camera.capabilities;
    final s = _camera.settings;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        key: const Key('pro-camera'),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(context, s),
              Expanded(child: Center(child: _preview(context))),
              const SizedBox(height: 6),
              _readouts(context, caps, s),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: _dial == null
                    ? const SizedBox(width: double.infinity)
                    : _dialPanel(context, caps, s),
              ),
              if (caps.zoomable)
                ZoomControl(
                  zoom: s.zoom,
                  min: caps.zoomMin,
                  max: caps.zoomMax,
                  onChanged: (z) => _set(s.copyWith(zoom: z)),
                )
              else
                const SizedBox(height: 24),
              _bottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _round(
    IconData icon,
    VoidCallback? onTap, {
    required String tooltip,
    Key? key,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        key: key,
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: active ? 0.2 : 0.08),
          ),
          child: Icon(icon, size: 19, color: active ? _accent : Colors.white),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, ProCameraSettings s) {
    final rawEnabled = _camera.rawAvailable;
    final rawOn = s.raw && rawEnabled;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          _round(
            Icons.close,
            () => Navigator.of(context).maybePop(),
            tooltip: context.tr('Close'),
            key: const Key('pro-close'),
          ),
          const Spacer(),
          Tooltip(
            message: rawEnabled
                ? context.tr('Also save RAW (DNG)')
                : context.tr('This phone does not give RAW to other apps'),
            child: GestureDetector(
              key: const Key('pro-raw'),
              onTap: rawEnabled
                  ? () {
                      HapticFeedback.selectionClick();
                      _set(s.copyWith(raw: !s.raw));
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: rawOn ? _accent : Colors.transparent,
                  border: Border.all(
                    color: rawEnabled
                        ? (rawOn ? _accent : Colors.white70)
                        : Colors.white24,
                  ),
                ),
                child: Text(
                  'RAW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
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
          const SizedBox(width: 10),
          _round(
            _grid ? Icons.grid_on : Icons.grid_off,
            () => setState(() => _grid = !_grid),
            tooltip: context.tr('Grid'),
            key: const Key('pro-grid'),
            active: _grid,
          ),
          if (_photo != null) ...[
            const SizedBox(width: 10),
            _round(
              _showGuide ? Icons.layers : Icons.layers_clear_outlined,
              () => setState(() => _showGuide = !_showGuide),
              tooltip: _showGuide
                  ? context.tr('Hide guide')
                  : context.tr('Show guide'),
              key: const Key('pro-guide'),
              active: _showGuide,
            ),
          ],
        ],
      ),
    );
  }

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
      return const CircularProgressIndicator(color: Colors.white54);
    }
    final photo = _photo;
    return AspectRatio(
      aspectRatio: _camera.portraitAspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Texture(textureId: id),
            if (photo != null && _showGuide)
              IgnorePointer(
                child: Opacity(
                  opacity: _opacity,
                  child: PhotoReferenceImage(photo: photo),
                ),
              ),
            if (_grid)
              const IgnorePointer(child: CustomPaint(painter: _Grid())),
            if (photo != null && _showGuide)
              Positioned(
                right: 4,
                top: 48,
                bottom: 48,
                child: _OpacitySlider(
                  value: _opacity,
                  onChanged: (v) => setState(() => _opacity = v),
                ),
              ),
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _flash ? 0.6 : 0,
                duration: const Duration(milliseconds: 90),
                child: const ColoredBox(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _readout(_Dial dial, ProCameraCapabilities caps, ProCameraSettings s) {
    final manual = caps.manualSensor && !s.autoExposure;
    switch (dial) {
      case _Dial.iso:
        return manual ? '${s.iso}' : 'AUTO';
      case _Dial.shutter:
        return manual ? formatShutter(s.exposureNs) : 'AUTO';
      case _Dial.ev:
        return manual ? '—' : _signed(s.ev);
      case _Dial.wb:
        return _wbKelvin[s.whiteBalance] ?? 'AWB';
      case _Dial.focus:
        return s.autoFocus || !caps.manualFocus ? 'AF' : 'MF';
    }
  }

  bool _enabled(_Dial dial, ProCameraCapabilities caps) => switch (dial) {
    _Dial.iso || _Dial.shutter => caps.manualSensor,
    _Dial.ev => caps.exposureCompensation,
    _Dial.wb => caps.awbModes.length > 1,
    _Dial.focus => caps.manualFocus,
  };

  Widget _readouts(
    BuildContext context,
    ProCameraCapabilities caps,
    ProCameraSettings s,
  ) {
    final labels = {
      _Dial.iso: 'ISO',
      _Dial.shutter: context.tr('SHUTTER'),
      _Dial.ev: 'EV',
      _Dial.wb: context.tr('WB'),
      _Dial.focus: context.tr('FOCUS'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (final dial in _Dial.values)
            Expanded(
              child: GestureDetector(
                key: Key('pro-cell-${dial.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: _enabled(dial, caps)
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _dial = _dial == dial ? null : dial);
                      }
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Text(
                        labels[dial]!,
                        style: TextStyle(
                          fontSize: 9.5,
                          letterSpacing: 1,
                          color: _enabled(dial, caps)
                              ? (_dial == dial ? _accent : Colors.white54)
                              : Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _readout(dial, caps, s),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: _enabled(dial, caps)
                              ? (_dial == dial ? _accent : Colors.white)
                              : Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dialPanel(
    BuildContext context,
    ProCameraCapabilities caps,
    ProCameraSettings s,
  ) {
    Widget? lead;
    late Widget ruler;
    switch (_dial!) {
      case _Dial.iso:
        lead = _autoPill(
          s.autoExposure,
          () => _set(s.copyWith(autoExposure: true)),
        );
        ruler = RulerDial(
          key: const Key('pro-dial-iso'),
          position: logPosition(s.iso, caps.isoMin, caps.isoMax),
          steps: (3 * _stops(caps.isoMin, caps.isoMax)).round(),
          startLabel: '${caps.isoMin}',
          endLabel: '${caps.isoMax}',
          onChanged: (t) => _set(
            s.copyWith(
              autoExposure: false,
              iso: logValue(t, caps.isoMin, caps.isoMax).round(),
            ),
          ),
        );
      case _Dial.shutter:
        lead = _autoPill(
          s.autoExposure,
          () => _set(s.copyWith(autoExposure: true)),
        );
        // Left = fast, right = slow, as on a shutter dial.
        ruler = RulerDial(
          key: const Key('pro-dial-shutter'),
          position: logPosition(
            s.exposureNs,
            caps.exposureMinNs,
            caps.exposureMaxNs,
          ),
          steps: (3 * _stops(caps.exposureMinNs, caps.exposureMaxNs)).round(),
          startLabel: formatShutter(caps.exposureMinNs),
          endLabel: formatShutter(caps.exposureMaxNs),
          onChanged: (t) => _set(
            s.copyWith(
              autoExposure: false,
              exposureNs: logValue(
                t,
                caps.exposureMinNs,
                caps.exposureMaxNs,
              ).round(),
            ),
          ),
        );
      case _Dial.ev:
        final enabled = !(caps.manualSensor && !s.autoExposure);
        final min = caps.evMin * caps.evStep;
        final max = caps.evMax * caps.evStep;
        ruler = RulerDial(
          key: const Key('pro-dial-ev'),
          enabled: enabled,
          position: max > min ? (s.ev - min) / (max - min) : 0.5,
          steps: caps.evMax - caps.evMin,
          majorEvery: (1 / caps.evStep).round().clamp(1, 12),
          startLabel: _signed(min),
          endLabel: _signed(max),
          onChanged: (t) {
            final step = (t * (caps.evMax - caps.evMin)).round() + caps.evMin;
            _set(s.copyWith(ev: step * caps.evStep));
          },
        );
        if (!enabled) {
          lead = _hint(
            context.tr(
              'Exposure compensation works with automatic ISO and shutter.',
            ),
          );
        }
      case _Dial.wb:
        final modes = [
          for (final m in _wbOrder)
            if (caps.awbModes.contains(m)) m,
        ];
        final index = modes.indexOf(s.whiteBalance).clamp(0, modes.length - 1);
        ruler = RulerDial(
          key: const Key('pro-dial-wb'),
          position: modes.length > 1 ? index / (modes.length - 1) : 0,
          steps: modes.length - 1,
          majorEvery: 1,
          startLabel: 'AWB',
          endLabel: _wbKelvin[modes.last],
          onChanged: (t) => _set(
            s.copyWith(whiteBalance: modes[(t * (modes.length - 1)).round()]),
          ),
        );
      case _Dial.focus:
        lead = _autoPill(
          s.autoFocus,
          () => _set(s.copyWith(autoFocus: true)),
          label: 'AF',
        );
        ruler = RulerDial(
          key: const Key('pro-dial-focus'),
          position: caps.minFocusDiopters > 0
              ? s.focusDiopters / caps.minFocusDiopters
              : 0,
          startLabel: '∞',
          endLabel: context.tr('near'),
          onChanged: (t) => _set(
            s.copyWith(
              autoFocus: false,
              focusDiopters: t * caps.minFocusDiopters,
            ),
          ),
        );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
      child: Row(
        children: [
          ?lead,
          if (lead != null) const SizedBox(width: 8),
          Expanded(child: SizedBox(height: 46, child: ruler)),
        ],
      ),
    );
  }

  Widget _autoPill(bool active, VoidCallback onTap, {String label = 'AUTO'}) {
    return GestureDetector(
      key: Key('pro-auto-${_dial?.name}'),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: active ? _accent : Colors.white.withValues(alpha: 0.08),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: active ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _hint(String text) => SizedBox(
    width: 120,
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, color: Colors.white54),
    ),
  );

  Widget _bottomBar(BuildContext context) {
    final photo = _photo;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 2, 28, 18),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: photo == null
                  ? const SizedBox.shrink()
                  : _labelledRound(
                      icon: Icons.auto_fix_high,
                      label: context.tr('Apply photo settings'),
                      onTap: _ready ? _applyRecipe : null,
                      key: const Key('pro-apply-recipe'),
                    ),
            ),
          ),
          GestureDetector(
            key: const Key('pro-shutter'),
            onTap: _shoot,
            child: AnimatedScale(
              scale: _camera.busy ? 0.92 : 1,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                ),
                padding: const EdgeInsets.all(5),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: photo == null
                  ? const SizedBox.shrink()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        width: 46,
                        height: 46,
                        child: PhotoReferenceImage(
                          photo: photo,
                          thumbnail: true,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelledRound({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Key? key,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: SizedBox(
        width: 86,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: _accent, size: 21),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  static String _signed(double v) => v.abs() < 0.05
      ? '±0'
      : '${v > 0 ? '+' : '−'}${v.abs().toStringAsFixed(1)}';
}

/// Vertical see-through-guide slider on the preview's edge.
class _OpacitySlider extends StatelessWidget {
  const _OpacitySlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      child: RotatedBox(
        quarterTurns: 3,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.white,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
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
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 0.6;
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

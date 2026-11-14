import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app/theme.dart';
import '../../l10n/tr.dart';
import '../../shared/widgets/photo_reference_image.dart';
import '../discover/domain/photo_reference.dart';
import 'camera_recipe.dart';
import 'pro_camera_controller.dart';

enum _Control { iso, shutter, ev, wb, focus, zoom, guide }

const _wbLabels = {
  'auto': 'AWB',
  'incandescent': '3200K',
  'fluorescent': '4000K',
  'daylight': '5500K',
  'cloudy': '6500K',
  'shade': '7500K',
};

const _wbNames = {
  'auto': 'Auto',
  'incandescent': 'Tungsten',
  'fluorescent': 'Fluorescent',
  'daylight': 'Daylight',
  'cloudy': 'Cloudy',
  'shade': 'Shade',
};

/// SHOTBOOK's manual photo camera with the reference as a see-through
/// guide. [fallback] is shown when the phone has no native camera support.
class ProCameraView extends StatefulWidget {
  const ProCameraView({
    required this.photo,
    required this.fallback,
    required this.onOpened,
    super.key,
  });

  final PhotoReference photo;
  final WidgetBuilder fallback;

  /// Called once when the camera screen opens (counts as using the photo).
  final VoidCallback onOpened;

  @override
  State<ProCameraView> createState() => _ProCameraViewState();
}

class _ProCameraViewState extends State<ProCameraView>
    with WidgetsBindingObserver {
  final _camera = ProCameraController();
  bool _ready = false;
  bool _unsupported = false;
  String? _error;
  _Control _control = _Control.guide;
  double _opacity = 0.4;
  bool _showGuide = true;
  bool _grid = true;

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
    widget.onOpened();
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(
        () => _error =
            'Allow camera access in your phone settings to repeat a shot.',
      );
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

  Future<void> _update(ProCameraSettings next) async {
    try {
      await _camera.update(next);
    } on PlatformException {
      // The preview keeps the last working settings.
    }
  }

  void _applyRecipe() {
    final caps = _camera.capabilities;
    final recipe = CameraRecipe.fromPhoto(
      widget.photo,
      mainEquivalentMm: caps.mainEquivalentMm,
    );
    HapticFeedback.mediumImpact();
    _update(_camera.settings.withRecipe(recipe, caps));
    final manual =
        caps.manualSensor && recipe.iso != null && recipe.exposureNs != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
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
    final messenger = ScaffoldMessenger.of(context);
    final rawText = context.tr(
      'Saved to SHOTBOOK in your gallery: JPEG + RAW.',
    );
    final jpegText = context.tr('Saved to SHOTBOOK in your gallery.');
    final failText = context.tr('The photo could not be saved.');
    try {
      final result = await _camera.capture();
      messenger.showSnackBar(
        SnackBar(content: Text(result.dng != null ? rawText : jpegText)),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context, caps, s),
            Expanded(child: Center(child: _preview(context))),
            _controlStrip(context, caps, s),
            SizedBox(height: 84, child: _controlPanel(context, caps, s)),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _topBar(
    BuildContext context,
    ProCameraCapabilities caps,
    ProCameraSettings s,
  ) {
    final rawEnabled = _camera.rawAvailable;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('pro-close'),
            tooltip: context.tr('Close'),
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
          ),
          Expanded(
            child: Text(
              widget.photo.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Tooltip(
            message: rawEnabled
                ? context.tr('Also save RAW (DNG)')
                : context.tr('This phone does not give RAW to other apps'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RAW',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: rawEnabled
                        ? ShotbookColors.primary
                        : ShotbookColors.border,
                  ),
                ),
                Switch(
                  key: const Key('pro-raw'),
                  value: s.raw && rawEnabled,
                  onChanged: rawEnabled
                      ? (value) => _update(s.copyWith(raw: value))
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Text(context.tr(_error!), textAlign: TextAlign.center),
      );
    }
    final id = _camera.textureId;
    if (!_ready || id == null) return const CircularProgressIndicator();
    return AspectRatio(
      aspectRatio: _camera.portraitAspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Texture(textureId: id),
          if (_showGuide)
            IgnorePointer(
              child: Opacity(
                opacity: _opacity,
                child: PhotoReferenceImage(photo: widget.photo),
              ),
            ),
          if (_grid) const IgnorePointer(child: CustomPaint(painter: _Grid())),
        ],
      ),
    );
  }

  Widget _controlStrip(
    BuildContext context,
    ProCameraCapabilities caps,
    ProCameraSettings s,
  ) {
    final manualExposure = caps.manualSensor && !s.autoExposure;
    final cells = <(_Control, String, String, bool)>[
      (
        _Control.iso,
        'ISO',
        manualExposure ? '${s.iso}' : 'A',
        caps.manualSensor,
      ),
      (
        _Control.shutter,
        context.tr('SHUTTER'),
        manualExposure ? formatShutter(s.exposureNs) : 'A',
        caps.manualSensor,
      ),
      (
        _Control.ev,
        'EV',
        manualExposure ? '—' : _signed(s.ev),
        caps.exposureCompensation,
      ),
      (_Control.wb, context.tr('WB'), _wbLabels[s.whiteBalance] ?? 'AWB', true),
      (
        _Control.focus,
        context.tr('FOCUS'),
        s.autoFocus || !caps.manualFocus ? 'AF' : 'MF',
        caps.manualFocus,
      ),
      (_Control.zoom, 'ZOOM', '${_trim(s.zoom)}×', caps.zoomable),
      (
        _Control.guide,
        context.tr('GUIDE'),
        _showGuide ? '${(_opacity * 100).round()}%' : context.tr('OFF'),
        true,
      ),
    ];
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          for (final (control, label, value, enabled) in cells)
            Expanded(
              child: InkWell(
                key: Key('pro-cell-${control.name}'),
                onTap: enabled
                    ? () => setState(() => _control = control)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        width: 2,
                        color: _control == control
                            ? ShotbookColors.primary
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 0.6,
                          color: enabled
                              ? ShotbookColors.secondary
                              : ShotbookColors.border,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? ShotbookColors.primary
                              : ShotbookColors.border,
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

  Widget _controlPanel(
    BuildContext context,
    ProCameraCapabilities caps,
    ProCameraSettings s,
  ) {
    switch (_control) {
      case _Control.iso:
        return _stops<int>(
          context,
          auto: s.autoExposure,
          onAuto: () => _update(s.copyWith(autoExposure: true)),
          values: isoStops(caps.isoMin, caps.isoMax),
          selected: s.autoExposure ? null : s.iso,
          label: (v) => '$v',
          onSelect: (v) => _update(s.copyWith(autoExposure: false, iso: v)),
        );
      case _Control.shutter:
        return _stops<int>(
          context,
          auto: s.autoExposure,
          onAuto: () => _update(s.copyWith(autoExposure: true)),
          values: shutterStops(caps.exposureMinNs, caps.exposureMaxNs),
          selected: s.autoExposure ? null : s.exposureNs,
          label: formatShutter,
          onSelect: (v) =>
              _update(s.copyWith(autoExposure: false, exposureNs: v)),
        );
      case _Control.ev:
        if (!s.autoExposure && caps.manualSensor) {
          return _note(
            context,
            context.tr(
              'Exposure compensation works with automatic ISO and shutter.',
            ),
          );
        }
        return _slider(
          value: s.ev,
          min: caps.evMin * caps.evStep,
          max: caps.evMax * caps.evStep,
          divisions: caps.evMax - caps.evMin,
          label: _signed(s.ev),
          onChanged: (v) => _update(s.copyWith(ev: v)),
        );
      case _Control.wb:
        return _stops<String>(
          context,
          values: [
            for (final mode in _wbLabels.keys)
              if (caps.awbModes.contains(mode)) mode,
          ],
          selected: s.whiteBalance,
          label: (v) =>
              '${context.tr(_wbNames[v]!)} ${v == 'auto' ? '' : _wbLabels[v]}'
                  .trim(),
          onSelect: (v) => _update(s.copyWith(whiteBalance: v)),
        );
      case _Control.focus:
        return Row(
          children: [
            _autoButton(
              context,
              s.autoFocus,
              () => _update(s.copyWith(autoFocus: true)),
              label: 'AF',
            ),
            const Text('∞', style: TextStyle(color: ShotbookColors.secondary)),
            Expanded(
              child: Slider(
                key: const Key('pro-focus'),
                value: s.focusDiopters.clamp(0, caps.minFocusDiopters),
                max: caps.minFocusDiopters,
                onChanged: (v) =>
                    _update(s.copyWith(autoFocus: false, focusDiopters: v)),
              ),
            ),
            Text(
              context.tr('near'),
              style: const TextStyle(color: ShotbookColors.secondary),
            ),
            const SizedBox(width: 16),
          ],
        );
      case _Control.zoom:
        final presets = [0.6, 1.0, 2.0, 3.0, 5.0, 10.0]
            .where((z) => z >= caps.zoomMin - 0.01 && z <= caps.zoomMax + 0.01)
            .toList();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stops<double>(
              context,
              values: presets,
              selected: presets.contains(s.zoom) ? s.zoom : null,
              label: (v) => '${_trim(v)}×',
              onSelect: (v) => _update(s.copyWith(zoom: v)),
              height: 36,
            ),
            SizedBox(
              height: 40,
              child: _slider(
                value: s.zoom,
                min: caps.zoomMin,
                max: caps.zoomMax,
                label: '${_trim(s.zoom)}×',
                onChanged: (v) => _update(
                  s.copyWith(zoom: double.parse(v.toStringAsFixed(1))),
                ),
              ),
            ),
          ],
        );
      case _Control.guide:
        return Row(
          children: [
            _autoButton(
              context,
              !_showGuide,
              () => setState(() => _showGuide = !_showGuide),
              label: _showGuide ? context.tr('HIDE') : context.tr('SHOW'),
            ),
            Expanded(
              child: Slider(
                key: const Key('pro-guide-opacity'),
                value: _opacity,
                min: 0.1,
                max: 0.9,
                onChanged: _showGuide
                    ? (v) => setState(() => _opacity = v)
                    : null,
              ),
            ),
            IconButton(
              key: const Key('pro-grid'),
              tooltip: context.tr('Grid'),
              onPressed: () => setState(() => _grid = !_grid),
              icon: Icon(_grid ? Icons.grid_on : Icons.grid_off),
            ),
          ],
        );
    }
  }

  Widget _bottomBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                key: const Key('pro-apply-recipe'),
                onPressed: _ready ? _applyRecipe : null,
                child: Text(
                  context.tr('Apply photo settings'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          GestureDetector(
            key: const Key('pro-shutter'),
            onTap: _shoot,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              padding: const EdgeInsets.all(5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _camera.busy ? Colors.white54 : Colors.white,
                ),
              ),
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _stops<T>(
    BuildContext context, {
    required List<T> values,
    required T? selected,
    required String Function(T) label,
    required ValueChanged<T> onSelect,
    bool? auto,
    VoidCallback? onAuto,
    double height = 44,
  }) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          if (onAuto != null) _autoButton(context, auto == true, onAuto),
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(label(value)),
                selected: value == selected,
                showCheckmark: false,
                onSelected: (_) => onSelect(value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _autoButton(
    BuildContext context,
    bool active,
    VoidCallback onTap, {
    String label = 'AUTO',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _slider({
    required double value,
    required double min,
    required double max,
    required String label,
    required ValueChanged<double> onChanged,
    int? divisions,
  }) {
    if (max <= min) return const SizedBox.shrink();
    return Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions == null || divisions <= 0 ? null : divisions,
      label: label,
      onChanged: onChanged,
    );
  }

  Widget _note(BuildContext context, String text) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: ShotbookColors.secondary),
      ),
    ),
  );

  static String _signed(double v) =>
      v == 0 ? '0' : '${v > 0 ? '+' : '−'}${v.abs().toStringAsFixed(1)}';

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _Grid extends CustomPainter {
  const _Grid();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.7;
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';

const _accent = Color(0xFFFFD25A);

/// iPhone-style zoom: lens buttons in a small capsule; tapping one glides
/// to it, dragging across (or holding) opens a shallow wheel for smooth
/// zoom between the lenses. Sits over the bottom of the preview.
class ZoomControl extends StatefulWidget {
  const ZoomControl({
    required this.zoom,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  final double zoom;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  State<ZoomControl> createState() => _ZoomControlState();
}

class _ZoomControlState extends State<ZoomControl>
    with SingleTickerProviderStateMixin {
  bool _wheel = false;
  Timer? _hide;
  double? _lastLensClick;
  late final AnimationController _glide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  Animation<double>? _glideZoom;

  List<double> get _lenses => [
    0.6,
    1.0,
    2.0,
    3.0,
    5.0,
    10.0,
  ].where((z) => z >= widget.min - 0.01 && z <= widget.max + 0.01).toList();

  @override
  void initState() {
    super.initState();
    _glide.addListener(() {
      final z = _glideZoom?.value;
      if (z != null) widget.onChanged(double.parse(z.toStringAsFixed(2)));
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    _glide.dispose();
    super.dispose();
  }

  void _openWheel() {
    _hide?.cancel();
    _glide.stop();
    if (!_wheel) setState(() => _wheel = true);
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _wheel = false);
    });
  }

  void _glideTo(double lens) {
    HapticFeedback.selectionClick();
    // Zooming feels even on a log scale: 1→2 takes as long as 5→10.
    _glideZoom = Tween(begin: math.log(widget.zoom), end: math.log(lens))
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_glide)
        .drive(_ExpTween());
    _glide.forward(from: 0);
  }

  void _dragBy(double dx) {
    final logMin = math.log(widget.min);
    final logMax = math.log(widget.max);
    final current = math.log(widget.zoom.clamp(widget.min, widget.max));
    final next = (current - dx / 180).clamp(logMin, logMax);
    final zoom = double.parse(math.exp(next).toStringAsFixed(2));
    // A soft click when passing a lens.
    for (final lens in _lenses) {
      if ((zoom - lens).abs() / lens < 0.02 && _lastLensClick != lens) {
        _lastLensClick = lens;
        HapticFeedback.selectionClick();
      }
    }
    widget.onChanged(zoom);
  }

  static String _label(double z) {
    if ((z - z.roundToDouble()).abs() < 0.05) return z.round().toString();
    return z.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final lenses = _lenses;
    final active = lenses.lastWhere(
      (z) => widget.zoom + 0.05 >= z,
      orElse: () => lenses.isEmpty ? 1 : lenses.first,
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: _openWheel,
      onLongPressEnd: (_) => _scheduleHide(),
      onHorizontalDragStart: (_) => _openWheel(),
      onHorizontalDragUpdate: (d) => _dragBy(d.delta.dx),
      onHorizontalDragEnd: (_) => _scheduleHide(),
      child: SizedBox(
        height: 72,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _wheel
              ? RepaintBoundary(
                  key: const ValueKey('wheel'),
                  child: CustomPaint(
                    size: const Size(double.infinity, 72),
                    painter: _WheelPainter(
                      zoom: widget.zoom,
                      min: widget.min,
                      max: widget.max,
                      lenses: lenses,
                    ),
                  ),
                )
              : Align(
                  key: const ValueKey('lenses'),
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final lens in lenses)
                          GestureDetector(
                            key: Key('zoom-${_label(lens)}'),
                            onTap: () => _glideTo(lens),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              width: lens == active ? 36 : 30,
                              height: lens == active ? 36 : 30,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(
                                  alpha: lens == active ? 0.55 : 0.25,
                                ),
                              ),
                              child: Text(
                                lens == active
                                    ? '${_label(widget.zoom)}×'
                                    : _label(lens),
                                style: TextStyle(
                                  fontFamily: shotbookBodyFont,
                                  fontSize: lens == active ? 12 : 11,
                                  fontWeight: FontWeight.w600,
                                  color: lens == active
                                      ? _accent
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ExpTween extends Animatable<double> {
  @override
  double transform(double t) => math.exp(t);
}

/// A shallow arc of a large wheel, as on the iPhone: log-scale ticks,
/// lenses labelled, the current zoom under a fixed needle at the top.
class _WheelPainter extends CustomPainter {
  _WheelPainter({
    required this.zoom,
    required this.min,
    required this.max,
    required this.lenses,
  });

  final double zoom;
  final double min;
  final double max;
  final List<double> lenses;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final radius = size.width * 0.9;
    final center = Offset(size.width / 2, radius + 22);
    final logMin = math.log(min);
    final logMax = math.log(max);
    final logZoom = math.log(zoom.clamp(min, max));
    // One stop of zoom (×2) turns the wheel by 9°.
    const perLog = 9 * math.pi / 180 / math.ln2;
    const visible = 0.42; // radians either side of the top

    final shade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);

    double angleFor(double value) =>
        -math.pi / 2 + (math.log(value) - logZoom) * perLog;
    double fadeFor(double a) =>
        (1 - ((a + math.pi / 2).abs() / visible)).clamp(0.0, 1.0);

    final steps = ((logMax - logMin) / (math.ln2 / 10)).round();
    for (var i = 0; i <= steps; i++) {
      final value = math.exp(logMin + i * (logMax - logMin) / steps);
      final a = angleFor(value);
      final fade = fadeFor(a);
      if (fade <= 0) continue;
      final isLens = lenses.any((l) => (l - value).abs() / l < 0.035);
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: (isLens ? 1 : 0.45) * fade)
        ..strokeWidth = isLens ? 1.5 : 1;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (radius - (isLens ? 12 : 7)),
        center + dir * radius,
        paint,
      );
    }
    for (final lens in lenses) {
      final a = angleFor(lens);
      final fade = fadeFor(a);
      if (fade <= 0) continue;
      final p = center + Offset(math.cos(a), math.sin(a)) * (radius - 22);
      _text(
        canvas,
        _ZoomControlState._label(lens),
        p,
        10,
        Colors.white.withValues(alpha: fade),
      );
    }
    final top = center + Offset(0, -radius - 2);
    canvas.drawLine(
      top,
      top + const Offset(0, 16),
      Paint()
        ..color = _accent
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    _text(
      canvas,
      '${_ZoomControlState._label(zoom)}×',
      top + const Offset(0, -10),
      13,
      _accent,
    );
  }

  void _text(Canvas canvas, String text, Offset at, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: shotbookBodyFont,
          fontSize: size,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.zoom != zoom;
}

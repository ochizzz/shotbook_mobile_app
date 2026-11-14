import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// iPhone-style zoom: lens buttons in a capsule; drag across them (or hold)
/// and a half-circle dial opens for smooth zoom between the lenses.
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

class _ZoomControlState extends State<ZoomControl> {
  bool _dial = false;
  Timer? _hide;
  double? _lastWhole;

  List<double> get _lenses => [
    0.6,
    1.0,
    2.0,
    3.0,
    5.0,
    10.0,
  ].where((z) => z >= widget.min - 0.01 && z <= widget.max + 0.01).toList();

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _openDial() {
    _hide?.cancel();
    if (!_dial) setState(() => _dial = true);
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _dial = false);
    });
  }

  void _dragBy(double dx) {
    // Log scale: the same drag moves 1×→2× as 5×→10×.
    final logMin = math.log(widget.min);
    final logMax = math.log(widget.max);
    final current = math.log(widget.zoom.clamp(widget.min, widget.max));
    final next = (current - dx / 160).clamp(logMin, logMax);
    final zoom = double.parse(math.exp(next).toStringAsFixed(1));
    final whole = zoom.floorToDouble();
    if (_lenses.contains(zoom) || whole != _lastWhole) {
      _lastWhole = whole;
      HapticFeedback.selectionClick();
    }
    widget.onChanged(zoom);
  }

  String _label(double z) =>
      z == z.roundToDouble() ? z.toStringAsFixed(0) : z.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final lenses = _lenses;
    // The active lens is the largest one not above the current zoom.
    final active = lenses.lastWhere(
      (z) => widget.zoom + 0.05 >= z,
      orElse: () => lenses.isEmpty ? 1 : lenses.first,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: _openDial,
      onLongPressEnd: (_) => _scheduleHide(),
      onHorizontalDragStart: (_) => _openDial(),
      onHorizontalDragUpdate: (d) => _dragBy(d.delta.dx),
      onHorizontalDragEnd: (_) => _scheduleHide(),
      child: SizedBox(
        height: 92,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          child: _dial
              ? CustomPaint(
                  key: const ValueKey('dial'),
                  size: const Size(double.infinity, 92),
                  painter: _ArcPainter(
                    zoom: widget.zoom,
                    min: widget.min,
                    max: widget.max,
                    lenses: lenses,
                  ),
                )
              : Center(
                  key: const ValueKey('lenses'),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final lens in lenses)
                          GestureDetector(
                            key: Key('zoom-${_label(lens)}'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onChanged(lens);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: lens == active ? 44 : 36,
                              height: lens == active ? 44 : 36,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(
                                  alpha: lens == active ? 0.18 : 0.08,
                                ),
                              ),
                              child: Text(
                                lens == active
                                    ? '${_label(widget.zoom)}×'
                                    : _label(lens),
                                style: TextStyle(
                                  fontSize: lens == active ? 13 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: lens == active
                                      ? const Color(0xFFFFD25A)
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

/// Half-circle dial: ticks on a log scale, lens marks labelled, the current
/// zoom under a fixed needle at the top.
class _ArcPainter extends CustomPainter {
  _ArcPainter({
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
    // A shallow arc: only the top of a large circle shows, like the
    // iPhone zoom wheel. Everything stays inside the control's box.
    canvas.clipRect(Offset.zero & size);
    final radius = size.width * 0.9;
    final center = Offset(size.width / 2, radius + 26);
    final logMin = math.log(min);
    final logMax = math.log(max);
    final logZoom = math.log(zoom.clamp(min, max));
    // One stop of zoom (x2) turns the wheel by 9 degrees.
    const perLog = 9 * math.pi / 180 / math.ln2;
    const visible = 0.42; // radians either side of the top

    final shade = Paint()
      ..shader = RadialGradient(
        colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius + 40));
    canvas.drawCircle(center, radius + 40, shade);

    double angleFor(double value) =>
        -math.pi / 2 + (math.log(value) - logZoom) * perLog;
    bool shown(double a) => (a + math.pi / 2).abs() < visible;

    final steps = ((logMax - logMin) / (math.ln2 / 10)).round();
    for (var i = 0; i <= steps; i++) {
      final value = math.exp(logMin + i * (logMax - logMin) / steps);
      final a = angleFor(value);
      if (!shown(a)) continue;
      final fade = 1 - ((a + math.pi / 2).abs() / visible);
      final isLens = lenses.any((l) => (l - value).abs() / l < 0.035);
      final paint = Paint()
        ..color = Colors.white.withValues(
          alpha: (isLens ? 1.0 : 0.5) * fade.clamp(0.0, 1.0),
        )
        ..strokeWidth = isLens ? 1.6 : 1;
      final inner = radius - (isLens ? 14 : 8);
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * inner,
        center + Offset(math.cos(a), math.sin(a)) * radius,
        paint,
      );
    }
    for (final lens in lenses) {
      final a = angleFor(lens);
      if (!shown(a)) continue;
      final fade = (1 - ((a + math.pi / 2).abs() / visible)).clamp(0.0, 1.0);
      final p = center + Offset(math.cos(a), math.sin(a)) * (radius - 26);
      _text(
        canvas,
        lens == lens.roundToDouble()
            ? lens.toStringAsFixed(0)
            : lens.toStringAsFixed(1),
        p,
        11,
        Colors.white.withValues(alpha: fade),
      );
    }
    final needle = Paint()
      ..color = const Color(0xFFFFD25A)
      ..strokeWidth = 2;
    final top = center + Offset(0, -radius - 4);
    canvas.drawLine(top, top + const Offset(0, 20), needle);
    _text(
      canvas,
      '${zoom == zoom.roundToDouble() ? zoom.toStringAsFixed(0) : zoom.toStringAsFixed(1)}×',
      top + const Offset(0, -12),
      14,
      const Color(0xFFFFD25A),
    );
  }

  void _text(Canvas canvas, String text, Offset at, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
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
  bool shouldRepaint(covariant _ArcPainter old) => old.zoom != zoom;
}

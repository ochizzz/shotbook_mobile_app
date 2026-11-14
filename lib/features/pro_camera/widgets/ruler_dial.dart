import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A horizontal tick ruler you drag like a lens ring (as in pro camera
/// apps). [position] runs 0…1 across the whole range. With [steps] the
/// ruler snaps to step marks and clicks softly on each one.
class RulerDial extends StatefulWidget {
  const RulerDial({
    required this.position,
    required this.onChanged,
    this.steps,
    this.majorEvery = 3,
    this.startLabel,
    this.endLabel,
    this.enabled = true,
    super.key,
  });

  final double position;
  final ValueChanged<double> onChanged;
  final int? steps;
  final int majorEvery;
  final String? startLabel;
  final String? endLabel;
  final bool enabled;

  @override
  State<RulerDial> createState() => _RulerDialState();
}

class _RulerDialState extends State<RulerDial> {
  late double _raw = widget.position;
  int? _lastStep;

  @override
  void didUpdateWidget(covariant RulerDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) _raw = widget.position;
  }

  bool _dragging = false;

  void _drag(double dx, double span) {
    final steps = widget.steps;
    _raw = (_raw - dx / span).clamp(0.0, 1.0);
    var t = _raw;
    if (steps != null && steps > 0) {
      final step = (t * steps).round();
      t = step / steps;
      if (step != _lastStep) {
        _lastStep = step;
        HapticFeedback.selectionClick();
      }
    }
    widget.onChanged(t);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The full range spans two screen widths: fine control, short drags.
        final span = constraints.maxWidth * 2;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: widget.enabled
              ? (_) {
                  _dragging = true;
                  _raw = widget.position;
                }
              : null,
          onHorizontalDragUpdate: widget.enabled
              ? (d) => _drag(d.delta.dx, span)
              : null,
          onHorizontalDragEnd: (_) => _dragging = false,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0, 0.18, 0.82, 1],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: CustomPaint(
              size: Size(constraints.maxWidth, 44),
              painter: _RulerPainter(
                position: widget.position,
                span: span,
                steps: widget.steps,
                majorEvery: widget.majorEvery,
                enabled: widget.enabled,
                startLabel: widget.startLabel,
                endLabel: widget.endLabel,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({
    required this.position,
    required this.span,
    required this.steps,
    required this.majorEvery,
    required this.enabled,
    this.startLabel,
    this.endLabel,
  });

  final double position;
  final double span;
  final int? steps;
  final int majorEvery;
  final bool enabled;
  final String? startLabel;
  final String? endLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final base = size.height - 8;
    final tick = Paint()
      ..color = Colors.white.withValues(alpha: enabled ? 0.55 : 0.2)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = Colors.white.withValues(alpha: enabled ? 0.9 : 0.25)
      ..strokeWidth = 1.4;
    // Continuous rulers still get evenly spaced marks to read the movement.
    final count = steps ?? 48;
    for (var i = 0; i <= count; i++) {
      final x = center + (i / count - position) * span;
      if (x < -2 || x > size.width + 2) continue;
      final isMajor = i % majorEvery == 0 || i == 0 || i == count;
      canvas.drawLine(
        Offset(x, base),
        Offset(x, base - (isMajor ? 16 : 9)),
        isMajor ? major : tick,
      );
    }
    void label(String text, double t) {
      final x = center + (t - position) * span;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x - painter.width / 2, 0));
    }

    if (startLabel != null) label(startLabel!, 0);
    if (endLabel != null) label(endLabel!, 1);
    // Fixed centre needle.
    final needle = Paint()
      ..color = const Color(0xFFFFD25A)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(center, base + 4),
      Offset(center, base - 22),
      needle,
    );
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.position != position || old.enabled != enabled;
}

/// Logarithmic mapping for ISO and shutter: equal drag = equal stops.
double logPosition(num value, num min, num max) {
  if (max <= min) return 0;
  return (math.log(value / min) / math.log(max / min)).clamp(0.0, 1.0);
}

double logValue(double t, num min, num max) =>
    (min * math.pow(max / min, t.clamp(0.0, 1.0))).toDouble();

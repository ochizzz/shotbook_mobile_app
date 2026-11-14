import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../app/theme.dart';

/// A tick ruler you spin like a lens ring, as in the iPhone and Pixel
/// cameras: it follows the finger smoothly, keeps gliding after a flick,
/// and settles softly on the nearest mark. [value] runs 0…1; with
/// [divisions] the reported value snaps to marks (with a light click).
class RulerDial extends StatefulWidget {
  const RulerDial({
    required this.value,
    required this.onChanged,
    this.divisions,
    this.majorEvery = 3,
    this.startLabel,
    this.endLabel,
    this.enabled = true,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final int? divisions;
  final int majorEvery;
  final String? startLabel;
  final String? endLabel;
  final bool enabled;

  @override
  State<RulerDial> createState() => _RulerDialState();
}

class _RulerDialState extends State<RulerDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.value,
  )..addListener(_emit);
  bool _touching = false;
  bool _settling = false;
  double _span = 600;
  double? _lastSent;

  @override
  void didUpdateWidget(covariant RulerDial old) {
    super.didUpdateWidget(old);
    // Outside changes (reset, recipe) glide to the new value.
    if (!_touching &&
        !_settling &&
        (widget.value - _snap(_pos.value)).abs() > 1e-6) {
      _lastSent = widget.value;
      _pos.animateTo(
        widget.value,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  double _snap(double t) {
    final d = widget.divisions;
    final clamped = t.clamp(0.0, 1.0);
    if (d == null || d <= 0) return clamped;
    return (clamped * d).round() / d;
  }

  void _emit() {
    if (!_touching && !_settling) return;
    final value = _snap(_pos.value);
    if (_lastSent != null && (value - _lastSent!).abs() < 1e-6) return;
    if (widget.divisions != null) HapticFeedback.selectionClick();
    _lastSent = value;
    widget.onChanged(value);
  }

  void _onStart(DragStartDetails _) {
    _pos.stop();
    _settling = false;
    _touching = true;
  }

  void _onUpdate(DragUpdateDetails d) {
    // Soft resistance past the ends, like a scroll view.
    var next = _pos.value - d.delta.dx / _span;
    if (next < 0 || next > 1) next = _pos.value - d.delta.dx / _span / 3;
    _pos.value = next;
  }

  Future<void> _onEnd(DragEndDetails d) async {
    _touching = false;
    _settling = true;
    final velocity = -d.velocity.pixelsPerSecond.dx / _span;
    // Where a flick would glide to, then settle on that mark softly.
    final glide = FrictionSimulation(0.05, _pos.value, velocity);
    final target = _snap(glide.finalX.clamp(0.0, 1.0));
    await _pos
        .animateWith(
          SpringSimulation(
            const SpringDescription(mass: 1, stiffness: 140, damping: 22),
            _pos.value,
            target,
            velocity,
          ),
        )
        .orCancel
        .catchError((Object _) {});
    _settling = false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The whole range spans about two screen widths.
        _span = constraints.maxWidth * 2;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: widget.enabled ? _onStart : null,
          onHorizontalDragUpdate: widget.enabled ? _onUpdate : null,
          onHorizontalDragEnd: widget.enabled ? _onEnd : null,
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(constraints.maxWidth, 38),
              painter: _RulerPainter(
                position: _pos,
                span: _span,
                divisions: widget.divisions,
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
    required this.divisions,
    required this.majorEvery,
    required this.enabled,
    this.startLabel,
    this.endLabel,
  }) : super(repaint: position);

  final Animation<double> position;
  final double span;
  final int? divisions;
  final int majorEvery;
  final bool enabled;
  final String? startLabel;
  final String? endLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final pos = position.value;
    final center = size.width / 2;
    final base = size.height - 6;
    final count = divisions ?? 60;
    // At most one tick every ~7 px, whatever the range.
    final stride = math.max(1, (count * 7 / span).ceil());
    final alpha = enabled ? 1.0 : 0.3;
    for (var i = 0; i <= count; i += stride) {
      final x = center + (i / count - pos) * span;
      if (x < 0 || x > size.width) continue;
      // Ticks fade towards the edges.
      final edge = 1 - ((x - center).abs() / center).clamp(0.0, 1.0);
      final isMajor = (i ~/ stride) % majorEvery == 0 || i == count;
      final paint = Paint()
        ..color = Colors.white.withValues(
          alpha: (isMajor ? 0.85 : 0.38) * alpha * (0.2 + 0.8 * edge),
        )
        ..strokeWidth = isMajor ? 1.2 : 1;
      canvas.drawLine(
        Offset(x, base),
        Offset(x, base - (isMajor ? 12 : 7)),
        paint,
      );
    }
    void label(String text, double t) {
      final x = center + (t - pos) * span;
      if (x < -30 || x > size.width + 30) return;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: shotbookBodyFont,
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.5 * alpha),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(x - painter.width / 2, 2));
    }

    if (startLabel != null) label(startLabel!, 0);
    if (endLabel != null) label(endLabel!, 1);
    final needle = Paint()
      ..color = const Color(0xFFFFD25A).withValues(alpha: alpha)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center, base + 2),
      Offset(center, base - 18),
      needle,
    );
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.enabled != enabled ||
      old.span != span ||
      old.divisions != divisions ||
      old.startLabel != startLabel ||
      old.endLabel != endLabel;
}

/// Logarithmic mapping for ISO and shutter: equal drag = equal stops.
double logPosition(num value, num min, num max) {
  if (max <= min) return 0;
  return (math.log(value / min) / math.log(max / min)).clamp(0.0, 1.0);
}

double logValue(double t, num min, num max) =>
    (min * math.pow(max / min, t.clamp(0.0, 1.0))).toDouble();

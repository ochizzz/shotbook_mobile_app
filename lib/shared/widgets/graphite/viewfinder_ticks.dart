import 'package:flutter/material.dart';

/// Viewfinder corner ticks over a photo (Graphite photo card): 10×1 px
/// marks, 8 px in from each corner, white at 55 %.
class ViewfinderTicks extends StatelessWidget {
  const ViewfinderTicks({
    this.inset = 8,
    this.length = 10,
    this.opacity = 0.55,
    super.key,
  });

  final double inset;
  final double length;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _TicksPainter(inset: inset, length: length, opacity: opacity),
    ),
  );
}

class _TicksPainter extends CustomPainter {
  const _TicksPainter({
    required this.inset,
    required this.length,
    required this.opacity,
  });

  final double inset;
  final double length;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF1F2F3).withValues(alpha: opacity)
      ..strokeWidth = 1;
    final l = inset, t = inset;
    final r = size.width - inset, b = size.height - inset;
    for (final (x, y, dx, dy) in [
      (l, t, 1.0, 1.0),
      (r, t, -1.0, 1.0),
      (l, b, 1.0, -1.0),
      (r, b, -1.0, -1.0),
    ]) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * length, y), paint);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * length), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TicksPainter old) =>
      old.inset != inset || old.length != length || old.opacity != opacity;
}

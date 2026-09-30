import 'package:flutter/material.dart';

import '../theme.dart';

/// The Trailtale mark – a dotted trail leading to a pin – painted in the
/// brand colors, the same drawing as the launcher icon.
class TrailtaleLogo extends StatelessWidget {
  const TrailtaleLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Trailtale logo',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _LogoPainter()),
      ),
    );
  }
}

/// Paints the mark on a 108 × 108 grid, scaled to the widget size.
class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  /// Trail dots sampled along the trail curve (see the launcher icon).
  static const _dots = [
    Offset(31.46, 78.77),
    Offset(33.32, 68.39),
    Offset(38.62, 59.64),
    Offset(48.55, 56.03),
    Offset(58.96, 54.14),
    Offset(62.47, 45.79),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 108, size.height / 108);
    final paint = Paint()..isAntiAlias = true;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 108, 108),
        const Radius.circular(24),
      ),
      paint..color = TrailtaleColors.ink,
    );

    paint.color = TrailtaleColors.paper;
    for (final dot in _dots) {
      canvas.drawCircle(dot, 2.75, paint);
    }
    canvas.drawCircle(const Offset(24, 86), 5.5, paint);

    final pin = Path()
      ..moveTo(51, 31)
      ..arcToPoint(const Offset(81, 31), radius: const Radius.circular(15))
      ..cubicTo(81, 42, 66, 57, 66, 57)
      ..cubicTo(66, 57, 51, 42, 51, 31)
      ..close();
    canvas.drawPath(pin, paint..color = TrailtaleColors.sunset);
    canvas.drawCircle(
      const Offset(66, 31),
      5.5,
      paint..color = TrailtaleColors.ink,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter oldDelegate) => false;
}

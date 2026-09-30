import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// The welcome picture: a dotted trail on a soft disc leading to a pin, in
/// the theme's colors.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: AppLocalizations.of(context).welcomeIllustration,
      image: true,
      child: Center(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _WelcomePainter(
              disc: scheme.surfaceContainerHigh,
              trail: scheme.onSurface,
              pin: scheme.tertiary,
              pinHole: scheme.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePainter extends CustomPainter {
  const _WelcomePainter({
    required this.disc,
    required this.trail,
    required this.pin,
    required this.pinHole,
  });

  final Color disc;
  final Color trail;
  final Color pin;
  final Color pinHole;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 300 × 300 grid.
    canvas.scale(size.width / 300, size.height / 300);
    final paint = Paint()..isAntiAlias = true;

    canvas.drawCircle(const Offset(150, 150), 130, paint..color = disc);

    // Dots along the trail curve from bottom left to the pin.
    paint.color = trail;
    const start = Offset(60, 240);
    const c1 = Offset(120, 215);
    const c2 = Offset(70, 165);
    const middle = Offset(135, 160);
    const c3 = Offset(200, 155);
    const c4 = Offset(215, 130);
    const end = Offset(198, 100);
    for (var i = 1; i <= 7; i++) {
      canvas.drawCircle(_cubic(start, c1, c2, middle, i / 8), 4, paint);
    }
    for (var i = 0; i <= 5; i++) {
      canvas.drawCircle(_cubic(middle, c3, c4, end, i / 6), 4, paint);
    }
    canvas.drawCircle(start, 9, paint);

    final pinPath = Path()
      ..moveTo(175, 60)
      ..arcToPoint(const Offset(235, 60), radius: const Radius.circular(30))
      ..cubicTo(235, 82, 205, 112, 205, 112)
      ..cubicTo(205, 112, 175, 82, 175, 60)
      ..close();
    canvas.drawPath(pinPath, paint..color = pin);
    canvas.drawCircle(const Offset(205, 60), 11, paint..color = pinHole);
  }

  static Offset _cubic(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * pow(u, 3).toDouble() +
        b * (3 * u * u * t) +
        c * (3 * u * t * t) +
        d * pow(t, 3).toDouble();
  }

  @override
  bool shouldRepaint(_WelcomePainter oldDelegate) =>
      oldDelegate.disc != disc ||
      oldDelegate.trail != trail ||
      oldDelegate.pin != pin ||
      oldDelegate.pinHole != pinHole;
}

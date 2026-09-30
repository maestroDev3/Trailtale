import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/ui/widgets/trailtale_logo.dart';

import '../../support/pump_app.dart';

void main() {
  group('TrailtaleLogo', () {
    testWidgets('paints the mark at the given size', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: Center(child: TrailtaleLogo(size: 64))),
      );

      expect(tester.getSize(find.byType(TrailtaleLogo)), const Size(64, 64));
      expect(
        find.descendant(
          of: find.byType(TrailtaleLogo),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('has a semantics label', (tester) async {
      await pumpApp(
        tester,
        const Scaffold(body: Center(child: TrailtaleLogo(size: 40))),
      );

      expect(find.bySemanticsLabel('Trailtale logo'), findsOneWidget);
    });
  });
}

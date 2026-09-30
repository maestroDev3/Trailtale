import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/ui/widgets/stat_tile.dart';

import '../../support/pump_app.dart';

void main() {
  group('StatTile', () {
    testWidgets('shows the value in the display font above the label', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: StatTile(value: '548', label: 'km'),
        ),
      );

      final value = tester.widget<Text>(find.text('548'));
      expect(value.style?.fontFamily, 'Fraunces');
      expect(find.text('km'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('548')).dy,
        lessThan(tester.getTopLeft(find.text('km')).dy),
      );
    });
  });
}

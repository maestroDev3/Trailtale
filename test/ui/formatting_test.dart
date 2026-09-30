import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/ui/formatting.dart';

void main() {
  group('formatKilometers', () {
    test('shows one decimal below 10 km', () {
      expect(formatKilometers(8400, 'en'), '8.4');
    });

    test('shows whole kilometers from 10 km', () {
      expect(formatKilometers(12400, 'en'), '12');
      expect(formatKilometers(548591, 'en'), '549');
    });

    test('shows zero without decimals', () {
      expect(formatKilometers(0, 'en'), '0');
    });

    test('uses the locale for separators', () {
      expect(formatKilometers(8400, 'de'), '8,4');
      expect(formatKilometers(1234000, 'en'), '1,234');
    });
  });
}

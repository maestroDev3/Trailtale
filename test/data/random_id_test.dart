import 'package:flutter_test/flutter_test.dart';
import 'package:trailtale/data/random_id.dart';

void main() {
  group('randomId', () {
    test('returns 32 lowercase hex characters', () {
      expect(randomId(), matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('returns a different id on every call', () {
      final ids = List.generate(100, (_) => randomId()).toSet();

      expect(ids, hasLength(100));
    });
  });
}

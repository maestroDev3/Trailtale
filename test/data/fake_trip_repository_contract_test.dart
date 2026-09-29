import 'package:flutter_test/flutter_test.dart';

import '../support/fake_trip_repository.dart';
import '../support/trip_repository_contract.dart';

void main() {
  group('FakeTripRepository', () {
    tripRepositoryContract(() async => FakeTripRepository());
  });
}

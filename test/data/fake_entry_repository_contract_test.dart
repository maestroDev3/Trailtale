import 'package:flutter_test/flutter_test.dart';

import '../support/entry_repository_contract.dart';
import '../support/fake_entry_repository.dart';

void main() {
  group('FakeEntryRepository', () {
    entryRepositoryContract(() async => FakeEntryRepository());
  });
}

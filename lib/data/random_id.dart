import 'dart:math';

final _random = Random.secure();

/// Creates a random 128-bit id as 32 lowercase hex characters, unique enough
/// to identify records across devices without coordination.
String randomId() => List.generate(
  16,
  (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
).join();

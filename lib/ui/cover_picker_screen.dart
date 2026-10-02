import 'package:flutter/material.dart';

import '../domain/entry.dart';
import '../domain/trip.dart';
import 'app_services.dart';

/// Every photo of the trip once, in time order.
List<String> tripPhotos(List<Entry> entries) => throw UnimplementedError();

/// Lets the traveler choose the cover photo of [trip].
class CoverPickerScreen extends StatelessWidget {
  const CoverPickerScreen({
    super.key,
    required this.services,
    required this.trip,
    required this.entries,
  });

  final AppServices services;
  final Trip trip;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) => const Scaffold();
}

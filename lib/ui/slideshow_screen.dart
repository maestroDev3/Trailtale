import 'package:flutter/material.dart';

import '../domain/trip.dart';
import 'app_services.dart';

/// Creates the trip slideshow as a PDF and shares it.
class SlideshowScreen extends StatelessWidget {
  const SlideshowScreen({
    super.key,
    required this.services,
    required this.trip,
  });

  final AppServices services;
  final Trip trip;

  @override
  Widget build(BuildContext context) => const Scaffold();
}

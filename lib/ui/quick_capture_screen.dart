import 'package:flutter/material.dart';

import 'app_services.dart';

/// Saves where the traveler is right now (home screen widget “I'm here”).
class QuickCaptureScreen extends StatelessWidget {
  const QuickCaptureScreen({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) => const Scaffold();
}

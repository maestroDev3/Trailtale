import 'package:flutter/material.dart';

import 'app_services.dart';

/// Turns photos shared by another app into entries.
class SharedPhotosScreen extends StatelessWidget {
  const SharedPhotosScreen({
    super.key,
    required this.services,
    required this.paths,
  });

  final AppServices services;
  final List<String> paths;

  @override
  Widget build(BuildContext context) => const Scaffold();
}

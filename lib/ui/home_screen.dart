import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Start screen of the app; lists the trips and, until there are any, shows an
/// empty state.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(l10n.appTitle)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyTrips(message: l10n.emptyTripsMessage),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

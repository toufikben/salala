import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// The screen for a phone that would not open the ledger at all.
///
/// Everything before `runApp` — opening the database, reading the stored
/// language, reading the lock digest — had no handler, so an exception there
/// meant the app never drew a frame: a black screen beside records that are
/// still on the phone, with nothing to say so and no trace for the breeder to
/// describe. This carries no state, reads no database and starts no scheduler,
/// so it cannot fail the way the launch did.
class StartupFailureScreen extends StatelessWidget {
  const StartupFailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salala',
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.startupFailedTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.startupFailedBody,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

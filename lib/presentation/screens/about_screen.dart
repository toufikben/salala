import 'package:flutter/material.dart';

import '../../core/build_info.dart';
import '../../core/l10n/app_localizations.dart';
import '../widgets/info_page.dart';

/// The one page that answers "what is this thing, and which build is on my phone".
///
/// The version is a compilation constant rather than a plugin read, and a test
/// against `pubspec.yaml` is what keeps the two from drifting.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InfoPage(
      title: l10n.aboutTitle,
      sections: <InfoSection>[InfoSection(l10n.appTitle, l10n.aboutBody)],
      extra: <Widget>[
        const Divider(height: 28),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.aboutVersion(appVersion)),
          // A CI build stamps its own tag; a local one shows nothing rather than
          // an empty row, which is what `buildTag.isNotEmpty` is for here exactly
          // as it is in Settings.
          subtitle: buildTag.isEmpty ? null : Text(buildTag),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.settingsLicenses),
          onTap: () => showLicensePage(
            context: context,
            applicationName: l10n.appTitle,
            applicationVersion: appVersion,
          ),
        ),
      ],
    );
  }
}

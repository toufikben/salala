import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../widgets/info_page.dart';

/// The page an app with no server owes its user most.
///
/// Three questions, and the third is the one that matters: a backup is a file
/// full of buyers' names and phone numbers, and the app says so on the page that
/// also says "nothing leaves this phone". An app that shouted only the second half
/// would be telling the truth and hiding it at the same time.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InfoPage(
      title: l10n.privacyTitle,
      sections: <InfoSection>[
        InfoSection(l10n.appTitle, l10n.privacyIntro),
        InfoSection(l10n.privacyStoredHeading, l10n.privacyStoredBody),
        InfoSection(l10n.privacyBackupHeading, l10n.privacyBackupBody),
        InfoSection(l10n.privacyCollectHeading, l10n.privacyCollectBody),
        InfoSection(l10n.privacyRemoveHeading, l10n.privacyRemoveBody),
      ],
    );
  }
}

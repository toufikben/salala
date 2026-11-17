import 'package:flutter/material.dart';

import '../../core/build_info.dart';
import '../../core/l10n/app_localizations.dart';
import '../widgets/info_page.dart';

/// The release notes, in the app rather than only in a store listing.
///
/// A store listing describes the app a new breeder is installing; this page
/// describes the version the app just became, which is the thing an existing user
/// cannot otherwise find out. Five lines and a version number, because a changelog
/// that is longer than the phone's screen is a changelog nobody scrolls.
class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InfoPage(
      title: l10n.whatsNewTitle,
      bullets: <String>[
        l10n.whatsNew1,
        l10n.whatsNew2,
        l10n.whatsNew3,
        l10n.whatsNew4,
        l10n.whatsNew5,
      ],
      extra: <Widget>[
        const SizedBox(height: 8),
        Text(
          l10n.aboutVersion(appVersion),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}

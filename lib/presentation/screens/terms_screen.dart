import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../widgets/info_page.dart';

/// The four sentences a breeder is agreeing to, in the order they matter: what
/// the app is for, that the data is theirs and unbacked-up by anyone but them,
/// that it is not a diagnosis, and that nothing is guaranteed.
///
/// Written as four sections rather than one wall of text because the second and
/// third are the two a person will actually be held to, and burying them is how a
/// terms page becomes a thing nobody read.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return InfoPage(
      title: l10n.termsTitle,
      sections: <InfoSection>[
        InfoSection(l10n.termsUseHeading, l10n.termsUseBody),
        InfoSection(l10n.termsDataHeading, l10n.termsDataBody),
        InfoSection(l10n.termsAdviceHeading, l10n.termsAdviceBody),
        InfoSection(l10n.termsWarrantyHeading, l10n.termsWarrantyBody),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/contact.dart';
import '../../core/l10n/app_localizations.dart';

/// Eight questions, each one a thing a breeder has actually asked — and the four
/// that matter most are the ones about losing something: the PIN, the phone, the
/// file, the record.
///
/// An `ExpansionTile` per pair rather than a scrolling wall: the page's job is to
/// be scannable for the one question the reader has, and a page where every answer
/// is already open is a page nobody reads to the end.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final pairs = <(String, String)>[
      (l10n.helpQ1, l10n.helpA1),
      (l10n.helpQ2, l10n.helpA2),
      (l10n.helpQ3, l10n.helpA3),
      (l10n.helpQ4, l10n.helpA4),
      (l10n.helpQ5, l10n.helpA5),
      (l10n.helpQ6, l10n.helpA6),
      (l10n.helpQ7, l10n.helpA7),
      (l10n.helpQ8, l10n.helpA8),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          for (final pair in pairs)
            ExpansionTile(
              title: Text(pair.$1),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pair.$2,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(height: 1.5),
                ),
              ],
            ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l10n.helpContactHeading),
            // Shown, not launched: an app with no intents to declare is an app
            // that cannot be accused of reaching anywhere it did not say. The
            // address is a real inbox, so it can be typed from another device.
            subtitle: const SelectableText(AppContact.supportEmail),
          ),
        ],
      ),
    );
  }
}

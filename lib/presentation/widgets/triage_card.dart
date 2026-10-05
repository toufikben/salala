import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/triage_labels.dart';
import '../../core/utils/triage.dart';

/// The verdict the rule table reached for one animal, and the sentence that says
/// what the verdict is not.
///
/// A plain widget over a list of findings rather than a provider watcher, so the
/// rules can be shown to a test without a database and without the asset
/// bundle — the same split the rest of this app uses between reading and
/// deciding.
class TriageCard extends StatelessWidget {
  const TriageCard({super.key, required this.findings});

  final List<TriageFinding> findings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Findings arrive worst-first, so the first one is the headline.
    final top = findings.isEmpty ? null : findings.first.urgency;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  l10n.triageTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (top != null)
                  Text(
                    triageUrgencyLabel(l10n, top),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: _color(top, theme),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            if (findings.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.triageNothing,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            for (final finding in findings)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: _color(finding.urgency, theme),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        triageMessage(l10n, finding),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.triageNotDiagnosis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Urgency is colour plus a word, never colour alone: on a phone in sunlight,
/// and for the roughly one in twelve men with red-green deficiency, "act now"
/// has to survive without the red.
Color _color(TriageUrgency urgency, ThemeData theme) => switch (urgency) {
  TriageUrgency.actNow => theme.colorScheme.error,
  TriageUrgency.watch => theme.colorScheme.tertiary,
  TriageUrgency.routineVet => theme.colorScheme.primary,
};

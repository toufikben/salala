/// The dam's next heat, as a window rather than a date.
///
/// Rendered only for a female who is breeding stock and has at least two matings
/// on file, because that is the only case the record can support a forecast from.
/// Everything else is silence: a card that said "not enough history" on every
/// young bitch would be a permanent complaint about a file the breeder is still
/// filling in.
///
/// The card says three things and no more — when, how sure, and what it would
/// mean if a mating happened then. The last one is the reason the card exists:
/// a breeder planning a mating is really planning a whelping nine weeks later,
/// and the app already knows the gestation table.
library;

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/gestation.dart';
import '../../core/utils/heat_cycle.dart';

class HeatCycleCard extends StatelessWidget {
  const HeatCycleCard({
    super.key,
    required this.forecast,
    required this.species,
  });

  final HeatForecast forecast;

  /// The dam's species, for the whelping estimate under the window. Null when
  /// the animal's species has no gestation length on file.
  final String species;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final earliest = formatDay(context, forecast.earliest);
    final latest = formatDay(context, forecast.latest);

    // What a mating today would whelp: counted off the middle of the window,
    // because a range of whelping dates is not a thing a breeder can plan a
    // room around.
    final whelpMs = expectedWhelpingDate(
      species: species,
      matingDate: forecast.estimated,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.autorenew,
                  size: 18,
                  color: scheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.heatCardTitle,
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.heatCardWindow(earliest, latest),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              // Two different sentences: one gap is a coincidence the app will
              // not dress up as a pattern, and saying so is what keeps the other
              // sentence worth reading.
              forecast.confidence == HeatConfidence.steady
                  ? l10n.heatCardSteady('${forecast.observedCycles}')
                  : l10n.heatCardThin,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            if (whelpMs != null) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.pets_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.heatCardWhelping(
                          formatDay(context, whelpMs),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

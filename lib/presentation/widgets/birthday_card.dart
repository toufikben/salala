/// The one card on the herd page that is not about work.
///
/// Everything else on that screen is a booking, a dose, or an animal waiting for
/// attention. A birthday is the only line the app can print that is purely good
/// news, and it is also the thing a breeder of ten years still photographs. It
/// appears for two weeks ahead, disappears the day after, and never nags: there
/// is no dismiss button, because a card that came back tomorrow would be a
/// notification rather than a greeting.
///
/// Only animals at home are here — a dog who died is not celebrated, and the
/// query is the same `isAtHome` the agenda uses.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/triage_labels.dart' show daysPhrase;
import '../../core/router/app_router.dart';
import '../../core/utils/kennel_stats.dart';
import '../../data/models/animal.dart';

class BirthdayCard extends StatelessWidget {
  const BirthdayCard({super.key, required this.animals, required this.nowMs});

  final List<Animal> animals;

  /// Passed in rather than read from the clock so a test can stand on 3 June.
  final int nowMs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final soon = birthdaysSoon(animals, nowMs: nowMs);
    if (soon.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.cake_outlined,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.birthdayTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final birthday in soon)
              InkWell(
                onTap: () => context.push(AppPaths.animal(birthday.animalId)),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          // The age is the half a breeder reads first, so it is
                          // the sentence rather than a suffix to the name.
                          l10n.birthdayTurning(
                            birthday.name,
                            '${birthday.turning}',
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        birthday.days == 0
                            ? l10n.birthdayToday
                            : l10n.birthdayIn(
                                daysPhrase(l10n, birthday.days),
                              ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

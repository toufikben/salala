/// The ledger, added up.
///
/// A breeder with six years of records can see every row individually and none of
/// them together. This page is the four numbers she would otherwise count on her
/// fingers, plus the money — which is the one thing the app has always held and
/// never once totalled.
///
/// It is a *reading* page, not a dashboard: no charts, no trends, no comparison
/// with last year. A trend line drawn over eight handovers would be a shape made
/// of noise, and this market's breeders ask what they sold, not how the quarter
/// went.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/kennel_stats.dart';
import '../../core/utils/money.dart';
import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import '../../data/models/placement.dart';
import '../providers/app_providers.dart';
import '../providers/record_providers.dart';

class KennelStatsScreen extends ConsumerWidget {
  const KennelStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final animals = ref.watch(animalsProvider).value ?? const <Animal>[];
    final litters = ref.watch(littersProvider).value ?? const <Litter>[];
    final placements = ref.watch(placementsProvider).value ?? const <Placement>[];

    final stats = kennelStats(
      animals: animals,
      litters: litters,
      placements: placements,
      nowMs: DateTime.now().millisecondsSinceEpoch,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.statsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: <Widget>[
          _Group(
            title: l10n.statsHerdGroup,
            rows: <_Stat>[
              _Stat(l10n.statsAtHome, '${stats.atHome}'),
              _Stat(l10n.statsBreedingStock, '${stats.breedingStock}'),
              _Stat(l10n.statsFemales, '${stats.females}'),
              _Stat(l10n.statsMales, '${stats.males}'),
              // Said out loud rather than left implicit: the gap between the two
              // is the history the ledger is keeping, and a breeder who wonders
              // why the herd list is shorter than this number has the answer here.
              _Stat(l10n.statsEverRecorded, '${stats.everRecorded}'),
            ],
          ),
          _Group(
            title: l10n.statsBreedingGroup,
            rows: <_Stat>[
              _Stat(l10n.statsWhelpings, '${stats.whelpings}'),
              _Stat(l10n.statsPuppies, '${stats.puppiesRegistered}'),
              _Stat(
                l10n.statsPuppiesThisYear('${stats.thisYear}'),
                '${stats.puppiesThisYear}',
              ),
            ],
          ),
          _Group(
            title: l10n.statsMoneyGroup,
            rows: <_Stat>[
              _Stat(l10n.statsPlacements, '${stats.placements}'),
              // One line per currency, never one summed total: 2000 MAD and 2000
              // EUR are not 4000 of anything, and a single figure would be the app
              // inventing an exchange rate.
              for (final row in stats.revenue)
                _Stat(
                  row.currency.isEmpty
                      ? l10n.statsUnnamedCurrency
                      : row.currency,
                  formatPrice(row.total),
                  note: l10n.statsHandoverCount('${row.count}'),
                ),
              if (stats.revenue.isEmpty)
                _Stat(l10n.statsNoRevenue, '—'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.statsFooter,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// A heading and its rows, in a card so the groups read as groups.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<_Stat> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final row in rows) row,
          ],
        ),
      ),
    );
  }
}

/// One label, one number, and an optional quiet line under it.
class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.bodyMedium),
                if (note != null)
                  Text(
                    note!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

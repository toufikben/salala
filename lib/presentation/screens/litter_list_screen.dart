import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/gestation.dart';
import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import '../providers/app_providers.dart';
import '../widgets/animal_card.dart';
import '../widgets/salala_nav_bar.dart';

class LitterListScreen extends ConsumerWidget {
  const LitterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final litters = ref.watch(littersProvider);
    final animals = ref.watch(animalsProvider).value ?? const <Animal>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navLitters)),
      bottomNavigationBar: const SalalaNavBar(index: 1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppPaths.newLitter),
        icon: const Icon(Icons.add),
        label: Text(l10n.litterAdd),
      ),
      body: litters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: FilledButton(
            onPressed: () => ref.read(littersProvider.notifier).refresh(),
            child: Text(l10n.actionRetry),
          ),
        ),
        data: (list) => list.isEmpty
            ? const _EmptyBody()
            : ListView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                children: <Widget>[
                  for (final litter in list)
                    _LitterCard(litter: litter, animals: animals),
                ],
              ),
      ),
    );
  }
}

/// One whelping row: who was bred, when it happened or is due, and how many
/// puppies the ledger already holds for it.
class _LitterCard extends StatelessWidget {
  const _LitterCard({required this.litter, required this.animals});

  final Litter litter;
  final List<Animal> animals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final puppies = puppiesOf(animals, litter.id);
    final dam = animalById(animals, litter.damId);
    final sire = animalById(animals, litter.sireId);
    final expected = expectedWhelpingDate(
      species: dam?.species,
      matingDate: litter.matingDate,
    );

    final when = litter.whelpingDate != null
        ? formatDay(context, litter.whelpingDate)
        : expected != null
        ? l10n.litterExpected(formatDay(context, expected))
        : null;

    return Card(
      child: ListTile(
        onTap: () => context.push(AppPaths.litter(litter.id)),
        leading: CircleAvatar(
          child: Text(
            litter.name.isEmpty
                ? '?'
                : litter.name.substring(0, 1).toUpperCase(),
          ),
        ),
        title: Text(
          litter.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          <String>[
            '${dam?.name ?? l10n.litterDamMissing} × '
                '${sire?.name ?? l10n.litterSireUnknown}',
            ?when,
            l10n.litterPuppyCount(puppies.length),
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

/// A single whelping with its registered puppies.
class LitterDetailScreen extends ConsumerWidget {
  const LitterDetailScreen({super.key, required this.litterId});

  final String litterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final litters = ref.watch(littersProvider);
    final animals = ref.watch(animalsProvider).value ?? const <Animal>[];
    final matches = (litters.value ?? const <Litter>[]).where(
      (l) => l.id == litterId,
    );
    final litter = matches.isEmpty ? null : matches.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(litter?.name ?? l10n.navLitters),
        actions: <Widget>[
          if (litter != null)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, litter),
            ),
        ],
      ),
      body: litters.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: FilledButton(
            onPressed: () => ref.read(littersProvider.notifier).refresh(),
            child: Text(l10n.actionRetry),
          ),
        ),
        data: (_) {
          if (litter == null) {
            // Deleted while this screen was open; the list behind it is already
            // correct, so say so instead of rendering a phantom whelping.
            return Center(child: Text(l10n.litterGone));
          }
          final puppies = puppiesOf(animals, litter.id);
          final dam = animalById(animals, litter.damId);
          final expected = expectedWhelpingDate(
            species: dam?.species,
            matingDate: litter.matingDate,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      <String>[
                        dam?.name ?? l10n.litterDamMissing,
                        ' × ',
                        animalById(animals, litter.sireId)?.name ??
                            l10n.litterSireUnknown,
                      ].join(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    for (final row in <(String, int?)>[
                      (l10n.litterMatingDate, litter.matingDate),
                      (l10n.litterWhelpingDate, litter.whelpingDate),
                      (l10n.litterWeaningDate, litter.weaningDate),
                    ])
                      if (row.$2 != null)
                        Text('${row.$1}: ${formatDay(context, row.$2)}'),
                    if (litter.whelpingDate == null && expected != null)
                      Text(l10n.litterExpected(formatDay(context, expected))),
                    Text(l10n.litterPuppyCount(puppies.length)),
                    if (litter.notes != null && litter.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(litter.notes!),
                    ],
                  ],
                ),
              ),
              if (puppies.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.litterNoPuppies),
                )
              else
                for (final puppy in puppies) AnimalCard(animal: puppy),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Litter litter,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.litterDeleteTitle(litter.name)),
      content: Text(l10n.litterDeleteBody),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.actionDelete),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    await ref.read(littersProvider.notifier).delete(litter.id);
    if (context.mounted) context.pop();
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.family_restroom_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.litterEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.litterEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push(AppPaths.newLitter),
              icon: const Icon(Icons.add),
              label: Text(l10n.litterAdd),
            ),
          ],
        ),
      ),
    );
  }
}

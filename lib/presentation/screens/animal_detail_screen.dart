import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/weight.dart';
import '../../data/models/animal.dart';
import '../../data/models/health_test.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/vet_visit.dart';
import '../../data/models/weight_entry.dart';
import '../providers/app_providers.dart';
import '../providers/record_providers.dart';

/// One animal's whole ledger: identity, parentage, doses and weigh-ins.
class AnimalDetailScreen extends ConsumerWidget {
  const AnimalDetailScreen({super.key, required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final animalsAsync = ref.watch(animalsProvider);
    final animals = animalsAsync.value ?? const <Animal>[];
    final matches = animals.where((a) => a.id == animalId);
    final animal = matches.isEmpty ? null : matches.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(animal?.name ?? l10n.animalGone),
        actions: <Widget>[
          if (animal != null)
            IconButton(
              tooltip: l10n.actionEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(AppPaths.editAnimal(animal.id)),
            ),
        ],
      ),
      body: animalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: FilledButton(
            onPressed: () => ref.read(animalsProvider.notifier).refresh(),
            child: Text(l10n.actionRetry),
          ),
        ),
        data: (_) {
          if (animal == null) {
            return Center(child: Text(l10n.animalGone));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            children: <Widget>[
              _IdentityCard(animal: animal, animals: animals),
              _RecordSection(
                title: l10n.recordsVaccinations,
                addLabel: l10n.vaccinationAdd,
                onAdd: () => context.push(AppPaths.newVaccination(animal.id)),
                body: ref
                    .watch(vaccinationsForAnimalProvider(animal.id))
                    .when(
                      loading: () => const _SectionLoading(),
                      error: (error, stack) => _SectionError(
                        onRetry: () => ref.invalidate(
                          vaccinationsForAnimalProvider(animal.id),
                        ),
                      ),
                      data: (doses) => doses.isEmpty
                          ? _SectionEmpty(text: l10n.recordsEmpty)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final dose in doses)
                                  _VaccinationTile(
                                    dose: dose,
                                    nowMs: DateTime.now()
                                        .toUtc()
                                        .millisecondsSinceEpoch,
                                  ),
                              ],
                            ),
                    ),
              ),
              _RecordSection(
                title: l10n.recordsHealthTests,
                addLabel: l10n.healthTestAdd,
                onAdd: () => context.push(AppPaths.newHealthTest(animal.id)),
                body: ref
                    .watch(healthTestsForAnimalProvider(animal.id))
                    .when(
                      loading: () => const _SectionLoading(),
                      error: (error, stack) => _SectionError(
                        onRetry: () => ref.invalidate(
                          healthTestsForAnimalProvider(animal.id),
                        ),
                      ),
                      data: (tests) => tests.isEmpty
                          ? _SectionEmpty(text: l10n.recordsEmpty)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final test in tests)
                                  _HealthTestTile(
                                    test: test,
                                    nowMs: DateTime.now()
                                        .toUtc()
                                        .millisecondsSinceEpoch,
                                  ),
                              ],
                            ),
                    ),
              ),
              _RecordSection(
                title: l10n.recordsVisits,
                addLabel: l10n.visitAdd,
                onAdd: () => context.push(AppPaths.newVisit(animal.id)),
                body: ref
                    .watch(visitsForAnimalProvider(animal.id))
                    .when(
                      loading: () => const _SectionLoading(),
                      error: (error, stack) => _SectionError(
                        onRetry: () =>
                            ref.invalidate(visitsForAnimalProvider(animal.id)),
                      ),
                      data: (visits) => visits.isEmpty
                          ? _SectionEmpty(text: l10n.recordsEmpty)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final visit in visits)
                                  _VisitTile(visit: visit),
                              ],
                            ),
                    ),
              ),
              _RecordSection(
                title: l10n.recordsWeights,
                addLabel: l10n.weightAdd,
                onAdd: () => context.push(AppPaths.newWeight(animal.id)),
                body: ref
                    .watch(weightsForAnimalProvider(animal.id))
                    .when(
                      loading: () => const _SectionLoading(),
                      error: (error, stack) => _SectionError(
                        onRetry: () =>
                            ref.invalidate(weightsForAnimalProvider(animal.id)),
                      ),
                      data: (entries) => entries.isEmpty
                          ? _SectionEmpty(text: l10n.recordsEmpty)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                if (entries.length > 1)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      4,
                                      8,
                                      8,
                                    ),
                                    child: _WeightSparkline(entries: entries),
                                  ),
                                for (final entry in entries.reversed)
                                  _WeightTile(entry: entry),
                              ],
                            ),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Name, lineage and the paperwork a buyer asks to see.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.animal, required this.animals});

  final Animal animal;
  final List<Animal> animals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = <(String, String)>[
      (l10n.animalSpecies, animal.species),
      if (animal.breed != null && animal.breed!.isNotEmpty)
        (l10n.animalBreed, animal.breed!),
      (l10n.animalSex, sexLabel(l10n, animal.sex)),
      (l10n.animalStatus, statusLabel(l10n, animal.status)),
      if (animal.birthDate != null)
        (l10n.animalBirthDate, formatDay(context, animal.birthDate)),
      if (animal.color != null && animal.color!.isNotEmpty)
        (l10n.animalColor, animal.color!),
      if (animal.microchipId != null && animal.microchipId!.isNotEmpty)
        (l10n.animalMicrochip, animal.microchipId!),
      if (animal.registrationNo != null && animal.registrationNo!.isNotEmpty)
        (l10n.animalRegistrationNo, animal.registrationNo!),
      if (animal.registry != null && animal.registry!.isNotEmpty)
        (l10n.animalRegistry, animal.registry!),
      // Plain "Dam"/"Sire" rather than the form's "Dam (mother)": on a card the
      // label sits in a column of labels and the parenthetical is noise.
      (
        l10n.animalDam,
        animalById(animals, animal.damId)?.name ?? l10n.valueUnknown,
      ),
      (
        l10n.animalSire,
        animalById(animals, animal.sireId)?.name ?? l10n.valueUnknown,
      ),
      if (animal.deathDate != null)
        (l10n.animalDeathDate, formatDay(context, animal.deathDate)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (animal.isBreedingStock)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Chip(label: Text(l10n.homeBreedingStock)),
              ),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '${row.$1}: ${row.$2}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (animal.notes != null && animal.notes!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(animal.notes!),
            ],
          ],
        ),
      ),
    );
  }
}

/// A titled card with one "add" action: the shape every record section takes.
class _RecordSection extends StatelessWidget {
  const _RecordSection({
    required this.title,
    required this.addLabel,
    required this.onAdd,
    required this.body,
  });

  final String title;
  final String addLabel;
  final VoidCallback onAdd;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(addLabel),
                ),
              ],
            ),
          ),
          body,
        ],
      ),
    );
  }
}

class _VaccinationTile extends StatelessWidget {
  const _VaccinationTile({required this.dose, required this.nowMs});

  final Vaccination dose;
  final int nowMs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overdue = dose.isOverdue(nowMs);

    return ListTile(
      onTap: () => context.push(AppPaths.vaccination(dose.animalId, dose.id)),
      title: Text(dose.vaccineName),
      subtitle: Text(
        <String>[
          '${l10n.vaccinationGiven} ${formatDay(context, dose.dateAdministered)}',
          if (dose.nextDueDate != null)
            '${l10n.vaccinationNextDue} ${formatDay(context, dose.nextDueDate)}',
          if (dose.batchNumber != null && dose.batchNumber!.isNotEmpty)
            dose.batchNumber!,
        ].join(' · '),
      ),
      trailing: overdue
          ? _FlagBadge(label: l10n.vaccinationOverdue)
          : const Icon(Icons.chevron_right),
    );
  }
}

/// A screening result. The certificate number is the whole point of the row, so
/// it leads; the expiry flag is what stops a lapsed claim reading as a fact.
class _HealthTestTile extends StatelessWidget {
  const _HealthTestTile({required this.test, required this.nowMs});

  final HealthTest test;
  final int nowMs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      onTap: () => context.push(AppPaths.healthTest(test.animalId, test.id)),
      title: Text(test.testType),
      subtitle: Text(
        <String>[
          test.result,
          formatDay(context, test.testDate),
          if (test.certificateNo != null && test.certificateNo!.isNotEmpty)
            test.certificateNo!,
        ].join(' · '),
      ),
      trailing: test.isExpired(nowMs)
          ? _FlagBadge(label: l10n.healthTestExpired)
          : const Icon(Icons.chevron_right),
    );
  }
}

/// A consultation. The reason is the title because that is what a breeder
/// scans for; a visit with no reason still shows the clinic or the vet.
class _VisitTile extends StatelessWidget {
  const _VisitTile({required this.visit});

  final VetVisit visit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final who = <String?>[
      visit.clinicName,
      visit.vetName,
    ].where((s) => s != null && s.isNotEmpty).join(' · ');
    final hasReason = visit.reason != null && visit.reason!.isNotEmpty;
    // When there is no reason the clinic/vet already carries the title, so the
    // subtitle must not repeat it.
    final title = hasReason
        ? visit.reason!
        : (who.isEmpty ? l10n.visitNoReason : who);

    return ListTile(
      onTap: () => context.push(AppPaths.visit(visit.animalId, visit.id)),
      title: Text(title),
      subtitle: Text(
        <String>[
          formatDay(context, visit.visitDate),
          if (visit.outcome != null && visit.outcome!.isNotEmpty)
            visit.outcome!,
          if (hasReason && who.isNotEmpty) who,
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: colors.onErrorContainer),
      ),
    );
  }
}

/// Weigh-ins are append-only, so the row offers deletion and nothing else:
/// correcting a mis-typed measurement means removing it and adding it again.
class _WeightTile extends ConsumerWidget {
  const _WeightTile({required this.entry});

  final WeightEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      title: Text(formatWeight(entry.weightGrams)),
      subtitle: Text(
        <String>[
          formatDay(context, entry.measuredAt),
          if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
        ].join(' · '),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.actionDelete,
        onPressed: () => _confirmDeleteWeight(context, ref, entry),
      ),
    );
  }

  Future<void> _confirmDeleteWeight(
    BuildContext context,
    WidgetRef ref,
    WeightEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recordDeleteTitle),
        content: Text(l10n.weightDeleteBody),
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
    if (confirmed == true) await deleteWeight(ref, entry);
  }
}

/// The growth curve, drawn from the stored weigh-ins in time order.
class _WeightSparkline extends StatelessWidget {
  const _WeightSparkline({required this.entries});

  final List<WeightEntry> entries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          entries: entries,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.entries, required this.color});

  final List<WeightEntry> entries;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = entries.map((e) => e.weightGrams.toDouble()).toList();
    final low = values.reduce((a, b) => a < b ? a : b);
    final high = values.reduce((a, b) => a > b ? a : b);
    final span = high - low;
    final stepX = size.width / (values.length - 1);

    final points = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          i * stepX,
          // A flat series has no span to divide by; draw it through the middle.
          span == 0
              ? size.height / 2
              : size.height - (values[i] - low) / span * size.height,
        ),
    ];

    // `close: false` is what makes a polygon a polyline: the stroke runs through
    // the points without drawing back from the last weigh-in to the first.
    final line = Path()..addPolygon(points, false);
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.color != color;
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: LinearProgressIndicator(),
  );
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
    child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
  );
}

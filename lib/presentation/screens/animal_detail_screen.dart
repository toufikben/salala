import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money.dart';
import '../../core/utils/weight.dart';
import '../../data/models/animal.dart';
import '../../data/models/buyer.dart';
import '../../data/models/health_test.dart';
import '../../data/models/placement.dart';
import '../../data/models/symptom.dart';
import '../../data/models/vaccination.dart';
import '../../data/models/vet_visit.dart';
import '../../data/models/weight_entry.dart';
import '../../services/animal_pdf.dart';
import '../../services/pack_files.dart';
import '../../services/pdf_layout.dart';
import '../providers/app_providers.dart';
import '../providers/record_providers.dart';
import '../providers/triage_providers.dart';
import '../widgets/placement_dialog.dart';
import '../widgets/record_refusal.dart';
import '../widgets/symptom_dialog.dart';
import '../widgets/triage_card.dart';

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
              tooltip: l10n.pdfAction,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _sharePdfPack(context, ref, animal),
            ),
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
            // The last section is a weigh-in, and on a phone with a three-button
            // bar it sat under that bar with no scroll left to free it.
            padding: EdgeInsets.fromLTRB(
              8,
              8,
              8,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: <Widget>[
              _IdentityCard(animal: animal, animals: animals),
              // Above the records, because it is the one part of this page that
              // answers a question rather than showing what was typed.
              ref
                  .watch(triageForAnimalProvider(animal.id))
                  .when(
                    loading: () => const _SectionLoading(),
                    error: (error, stack) => _SectionError(
                      onRetry: () =>
                          ref.invalidate(triageForAnimalProvider(animal.id)),
                    ),
                    data: (findings) => TriageCard(findings: findings),
                  ),
              _RecordSection(
                title: l10n.recordsSymptoms,
                addLabel: l10n.symptomAdd,
                onAdd: () => showSymptomDialog(context, animalId: animal.id),
                body: ref
                    .watch(symptomsForAnimalProvider(animal.id))
                    .when(
                      loading: () => const _SectionLoading(),
                      error: (error, stack) => _SectionError(
                        onRetry: () => ref.invalidate(
                          symptomsForAnimalProvider(animal.id),
                        ),
                      ),
                      data: (records) => records.isEmpty
                          ? _SectionEmpty(text: l10n.recordsEmpty)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final record in records)
                                  _SymptomTile(symptom: record),
                              ],
                            ),
                    ),
              ),
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
              _PlacementSection(
                animalId: animal.id,
                placements: ref.watch(placementsForAnimalProvider(animal.id)),
                buyers: ref.watch(buyersProvider),
                onRetry: () {
                  ref.invalidate(placementsForAnimalProvider(animal.id));
                  ref.invalidate(buyersProvider);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Writes this animal's buyer pack and hands it to the share sheet.
///
/// The font is read on each tap instead of at startup: it is 431 KB, this app has
/// to open fast on a five-year-old phone, and a breeder makes a handful of these
/// documents. A failure leaves the ledger on screen with one line about it — no
/// dialog, because nothing in a PDF is worth interrupting a person for.
Future<void> _sharePdfPack(
  BuildContext context,
  WidgetRef ref,
  Animal animal,
) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);

  try {
    final baseFont = await rootBundle.load(pdfFontAsset);
    final bytes = await animalPackPdf(
      ref.read(daosProvider),
      animalId: animal.id,
      l10n: l10n,
      baseFont: baseFont,
    );
    final name = await ref
        .read(packFilesProvider)
        .shareBytes(pdfFileName(animal.name, DateTime.now()), bytes);
    messenger.showSnackBar(SnackBar(content: Text(l10n.packShared(name))));
  } catch (error) {
    debugPrint('PDF pack failed: $error');
    messenger.showSnackBar(SnackBar(content: Text(l10n.pdfFailed)));
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

/// A sign the breeder saw. Tapping it opens the same dialog, because `ongoing`
/// is what the rules read: the row that keeps the card alarming has to be the
/// row that can say it has passed.
class _SymptomTile extends StatelessWidget {
  const _SymptomTile({required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      onTap: () => showSymptomDialog(
        context,
        animalId: symptom.animalId,
        existing: symptom,
      ),
      title: Text(symptom.label),
      subtitle: Text(
        <String>[
          severityLabel(l10n, symptom.severity),
          symptom.ongoing ? l10n.symptomOngoing : l10n.symptomResolved,
          formatDay(context, symptom.observedAt),
          if (symptom.note != null && symptom.note!.isNotEmpty) symptom.note!,
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
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
      // The unit is localized; the order is left to the bidi algorithm, which
      // correctly puts the unit to the left of the number in an RTL row.
      title: Text(
        formatWeight(entry.weightGrams, kg: l10n.unitKg, g: l10n.unitGrams),
      ),
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
    if (confirmed != true) return;
    try {
      await deleteWeight(ref, entry);
    } catch (error) {
      if (context.mounted) refuseRecordDelete(context, error);
    }
  }
}

/// Who each animal went to, and the terms it went to them on.
///
/// Its own widget because a placement row needs two lists: this animal's
/// placements and the contacts they name. Both are read by the screen and handed
/// down rather than watched here, like every other section on this page: a
/// section this far down a lazy `ListView` does not exist until it is scrolled
/// to, and a query started at that moment has no real-time window left to answer
/// in — run `37560315166` lost eight tests that way, each one timing out on a
/// bar after sqflite had warned that the database was locked for ten seconds.
/// Reading here also keeps a buyer's name off a query per row, and by the time
/// the add button is pressed the contacts are already in hand, so the form opens
/// on a filled dropdown rather than an empty one.
class _PlacementSection extends StatelessWidget {
  const _PlacementSection({
    required this.animalId,
    required this.placements,
    required this.buyers,
    required this.onRetry,
  });

  final String animalId;
  final AsyncValue<List<Placement>> placements;
  final AsyncValue<List<Buyer>> buyers;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _RecordSection(
      title: l10n.recordsPlacements,
      addLabel: l10n.placementAdd,
      onAdd: () => showPlacementDialog(context, animalId: animalId),
      // A contact list that failed to read is not an empty one: the rows would
      // say "no buyer" about people who are in the ledger. So the rows wait for
      // both lists, and one retry covers both reads.
      body: placements.when(
        loading: () => const _SectionLoading(),
        error: (error, stack) => _SectionError(onRetry: onRetry),
        data: (rows) => buyers.when(
          loading: () => const _SectionLoading(),
          error: (error, stack) => _SectionError(onRetry: onRetry),
          data: (contacts) => rows.isEmpty
              ? _SectionEmpty(text: l10n.recordsEmpty)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final placement in rows)
                      _PlacementTile(
                        placement: placement,
                        buyer: buyerById(contacts, placement.buyerId),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// One handover. The buyer leads the row because that is the name a breeder
/// scans the ledger for; the day, the money and the guarantee are the detail.
class _PlacementTile extends StatelessWidget {
  const _PlacementTile({required this.placement, this.buyer});

  final Placement placement;
  final Buyer? buyer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = placement.currency;
    final price = placement.price;
    final guarantee = placement.guaranteeTerms;
    // Digits stay Latin and the line stays ungrouped (D21); the order of the
    // amount and its code is left to the bidi algorithm, which is how a weigh-in
    // row already reads `18.50 كغ` on an Arabic phone.
    final amount = price == null
        ? null
        : (currency == null || currency.isEmpty)
        ? formatPrice(price)
        : '${formatPrice(price)} $currency';
    final details = <String>[
      if (placement.placedDate != null)
        formatDay(context, placement.placedDate),
      ?amount,
      if (guarantee != null && guarantee.isNotEmpty) guarantee,
    ];

    return ListTile(
      onTap: () => showPlacementDialog(
        context,
        animalId: placement.animalId,
        existing: placement,
      ),
      title: Text(buyer?.name ?? l10n.placementNoBuyer),
      // A row that has nothing beyond the fact of a placement still has to say
      // it happened, so the subtitle is absent rather than an empty line.
      subtitle: details.isEmpty ? null : Text(details.join(' · ')),
      trailing: const Icon(Icons.chevron_right),
    );
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

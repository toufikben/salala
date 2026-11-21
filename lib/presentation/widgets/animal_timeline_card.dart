import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money.dart';
import '../../core/utils/timeline.dart';
import '../../core/utils/weight.dart';
import '../widgets/photo_thumb.dart';
import 'symptom_dialog.dart';

/// The animal's life in one list, newest first.
///
/// This is a *reading* of rows that are already on the page, not a seventh place
/// to write one: every row carries the record it came from and every tap goes to
/// the screen that record already has. The six sections below stay exactly as
/// they were, because they are where a breeder adds a dose; this is where she
/// answers "what happened, and in what order".
///
/// Six rows when collapsed. A phone's screen holds about that much under the
/// identity card, and a timeline that pushed the sections off the bottom of the
/// page would be a page whose main job — logging a new record — got harder the
/// longer the animal lived. The count of what is hidden is on the button, so
/// nothing is silently dropped.
class AnimalTimelineCard extends StatefulWidget {
  const AnimalTimelineCard({super.key, required this.events});

  final List<TimelineEvent> events;

  @override
  State<AnimalTimelineCard> createState() => _AnimalTimelineCardState();
}

/// How many rows this card shows before it offers the rest.
const int _collapsedRows = 6;

class _AnimalTimelineCardState extends State<AnimalTimelineCard> {
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final events = widget.events;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.timeline,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.timelineTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                child: Text(
                  l10n.timelineEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...<Widget>[
              for (final event in _visible(events))
                _TimelineRow(
                  key: ValueKey<String>(_identity(event)),
                  event: event,
                ),
              if (events.length > _collapsedRows)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextButton(
                      onPressed: () => setState(() => _all = !_all),
                      child: Text(
                        _all
                            ? l10n.timelineShowLess
                            : l10n.timelineShowAll('${events.length}'),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Iterable<TimelineEvent> _visible(List<TimelineEvent> events) =>
      _all ? events : events.take(_collapsedRows);

  /// One key per row, so a rebuild that adds a record does not renumber the list
  /// and lose the state of the rows above it.
  String _identity(TimelineEvent event) =>
      '${event.kind.name}:${event.ref}:${event.atMs}';
}

/// One dated line: what happened, when, and a tap into the record itself.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({super.key, required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final day = formatDay(context, event.atMs);

    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      leading: _Leading(event: event),
      title: Text(
        _title(l10n),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _subtitle(l10n, day),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: _onTap(context, l10n) == null
          ? null
          : const Icon(Icons.chevron_right, size: 18),
      onTap: _onTap(context, l10n),
    );
  }

  /// The record's own words. A dose is a vaccine name, a screening is its panel,
  /// a visit is why the vet was called — the thing a breeder scans for. The three
  /// events that *are* the kind (a birth has no title of its own) use the kind's
  /// own word instead.
  String _title(AppLocalizations l10n) => switch (event) {
    BornEvent() => l10n.timelineKindBorn,
    DiedEvent() => l10n.timelineKindDied,
    WhelpedEvent(:final litter) => litter.name,
    VaccinationEvent(:final dose) => dose.vaccineName,
    HealthTestEvent(:final test) => test.testType,
    VisitEvent(:final visit) => _visitTitle(l10n, visit.reason),
    SymptomEvent(:final symptom) => symptom.label,
    WeightEvent(:final entry) => formatWeight(
      entry.weightGrams,
      kg: l10n.unitKg,
      g: l10n.unitGrams,
    ),
    PhotoEvent() => l10n.timelineKindPhoto,
    PlacementEvent(:final placement) => formatPriceWithCurrency(
      placement.price,
      placement.currency,
      unknown: l10n.timelineKindPlacement,
    ),
  };

  static String _visitTitle(AppLocalizations l10n, String? reason) =>
      (reason == null || reason.isEmpty) ? l10n.visitNoReason : reason;

  /// The kind, then the day — the two facts every row shares — and whatever
  /// belongs to this kind alone after them.
  String _subtitle(AppLocalizations l10n, String day) {
    final kind = switch (event) {
      BornEvent() => l10n.timelineKindBorn,
      DiedEvent() => l10n.timelineKindDied,
      WhelpedEvent() => l10n.timelineKindWhelped,
      VaccinationEvent() => l10n.timelineKindVaccination,
      HealthTestEvent() => l10n.timelineKindHealthTest,
      VisitEvent() => l10n.timelineKindVisit,
      SymptomEvent() => l10n.timelineKindSymptom,
      WeightEvent() => l10n.timelineKindWeight,
      PhotoEvent() => l10n.timelineKindPhoto,
      PlacementEvent() => l10n.timelineKindPlacement,
    };
    return <String>[kind, day, ..._extra(l10n)].join(' · ');
  }

  /// The one detail worth a line for this kind, and nothing more. A row that
  /// repeated everything its own screen says would be a second, worse copy of it.
  List<String> _extra(AppLocalizations l10n) => switch (event) {
    BornEvent() => const <String>[],
    DiedEvent() => const <String>[],
    WhelpedEvent() => const <String>[],
    // A dose reads as overdue in its own section, where it can be acted on. Here
    // it is history, and a red flag on a shot given last March would be a
    // warning about something that has already happened.
    VaccinationEvent() => const <String>[],
    HealthTestEvent(:final test) => <String>[test.result],
    VisitEvent(:final visit) => <String>[
      if (visit.clinicName != null && visit.clinicName!.isNotEmpty)
        visit.clinicName!,
    ],
    SymptomEvent(:final symptom) => <String>[
      severityLabel(l10n, symptom.severity),
      symptom.ongoing ? l10n.symptomOngoing : l10n.symptomResolved,
    ],
    WeightEvent(:final entry) => <String>[
      if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
    ],
    PhotoEvent() => const <String>[],
    PlacementEvent() => <String>[],
  };

  /// Where a tap goes, or null when the row has no screen of its own.
  ///
  /// A birth and a death are facts on the animal's own form, so their row is the
  /// animal page and the tap does nothing. A picture has no screen — its only
  /// action is delete, which lives in the photo strip — and sending a thumb to a
  /// page that cannot show it full-size would be a door onto a wall.
  VoidCallback? _onTap(BuildContext context, AppLocalizations l10n) =>
      switch (event) {
        BornEvent() || DiedEvent() => null,
        WhelpedEvent(:final litter) => () => context.push(
          AppPaths.litter(litter.id),
        ),
        VaccinationEvent(:final dose) => () => context.push(
          AppPaths.vaccination(dose.animalId, dose.id),
        ),
        HealthTestEvent(:final test) => () => context.push(
          AppPaths.healthTest(test.animalId, test.id),
        ),
        VisitEvent(:final visit) => () => context.push(
          AppPaths.visit(visit.animalId, visit.id),
        ),
        SymptomEvent(:final symptom) => () => showSymptomDialog(
          context,
          animalId: symptom.animalId,
          existing: symptom,
        ),
        WeightEvent() => null,
        PhotoEvent() => null,
        PlacementEvent() => null,
      };
}

/// An icon per kind, and the picture itself for a picture.
class _Leading extends StatelessWidget {
  const _Leading({required this.event});

  final TimelineEvent event;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    final colors = Theme.of(context).colorScheme;

    if (event case PhotoEvent(:final photo)) {
      return PhotoImage(
        photo: photo,
        width: size,
        height: size,
        radius: AppRadius.photo,
        missing: const Icon(Icons.broken_image_outlined, size: 18),
      );
    }

    final (IconData icon, Color tint) = switch (event) {
      BornEvent() => (Icons.favorite_border, colors.primary),
      DiedEvent() => (Icons.spa_outlined, colors.onSurfaceVariant),
      WhelpedEvent() => (Icons.pets_outlined, colors.primary),
      VaccinationEvent() => (Icons.vaccines_outlined, colors.primary),
      HealthTestEvent() => (Icons.science_outlined, colors.primary),
      VisitEvent() => (Icons.local_hospital_outlined, colors.primary),
      SymptomEvent(:final symptom) => (
        Icons.visibility_outlined,
        symptom.ongoing ? colors.error : colors.onSurfaceVariant,
      ),
      WeightEvent() => (Icons.monitor_weight_outlined, colors.onSurfaceVariant),
      PhotoEvent() => (Icons.photo_outlined, colors.onSurfaceVariant),
      PlacementEvent() => (Icons.handshake_outlined, colors.onSurfaceVariant),
    };

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.photo),
        ),
        child: Icon(icon, size: 18, color: tint),
      ),
    );
  }
}

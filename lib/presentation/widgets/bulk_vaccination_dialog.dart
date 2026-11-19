/// One vial, one sitting, a whole litter.
///
/// A breeder vaccinated nine puppies this morning and the app asked her to type
/// the same row nine times, once per animal, between holding one puppy and the
/// next. That is not a slow screen — it is a screen that produces a half-recorded
/// litter, because the sixth puppy gets written tomorrow or not at all.
///
/// The dialog writes the same dose for every animal handed to it, in one
/// transaction, and books the same reminder against each. Nothing here decides
/// *who* gets it: the caller passes the list, which is the litter's puppies on the
/// litter page and the selected animals on the herd screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../../data/models/vaccination.dart';
import '../providers/agenda_providers.dart';
import '../providers/app_providers.dart';
import '../providers/record_providers.dart';
import 'date_tile.dart';

/// Opens the dialog and writes the doses. Returns the number written, or null
/// when the breeder backed out.
Future<int?> showBulkVaccinationDialog(
  BuildContext context, {
  required List<Animal> animals,
}) {
  if (animals.isEmpty) return Future<int?>.value(null);
  return showDialog<int>(
    context: context,
    builder: (dialogContext) => _BulkVaccinationDialog(animals: animals),
  );
}

class _BulkVaccinationDialog extends ConsumerStatefulWidget {
  const _BulkVaccinationDialog({required this.animals});

  final List<Animal> animals;

  @override
  ConsumerState<_BulkVaccinationDialog> createState() =>
      _BulkVaccinationDialogState();
}

class _BulkVaccinationDialogState
    extends ConsumerState<_BulkVaccinationDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _vaccineName = TextEditingController();

  late int? _administered;
  int? _nextDue;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _administered = msFromDay(DateTime.now());
  }

  @override
  void dispose() {
    _vaccineName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Read here, once: the reminder loop below runs after two awaits, and a
    // `context` that has gone away cannot say which language the alarm's date
    // should be written in.
    final localeTag = Localizations.localeOf(context).toString();
    setState(() => _saving = true);

    final administered = _administered;
    if (administered == null) {
      setState(() => _saving = false);
      return;
    }

    final drafts = <Vaccination>[
      for (final animal in widget.animals)
        Vaccination(
          id: '',
          animalId: animal.id,
          vaccineName: _vaccineName.text.trim(),
          dateAdministered: administered,
          nextDueDate: _nextDue,
          createdAt: 0,
          updatedAt: 0,
        ),
    ];

    final List<Vaccination> written;
    try {
      written = await ref
          .read(daosProvider)
          .vaccinations
          .createAll(drafts);
    } catch (error) {
      debugPrint('Bulk vaccination failed: $error');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.recordSaveFailed)),
      );
      return;
    }

    // The rows are in the ledger; the alarms are the phone's business. A refused
    // alarm is not a refused dose, and the launch resync rebuilds them from the
    // rows anyway, so this loop logs and carries on rather than undoing a write
    // that already happened.
    for (final dose in written) {
      ref.invalidate(vaccinationsForAnimalProvider(dose.animalId));
      try {
        if (!reminderAllowedFor(ref, dose.animalId)) continue;
        await ref
            .read(reminderSchedulerProvider)
            .replace(
              recordId: dose.id,
              animalId: dose.animalId,
              dueMs: dose.nextDueDate,
              l10n: l10n,
              title: reminderTitle(ref, l10n, dose.animalId),
              what: dose.vaccineName,
              dueDay: formatDayFor(localeTag, dose.nextDueDate),
            );
      } catch (error) {
        debugPrint('Reminder after a bulk dose failed: $error');
      }
    }
    ref.invalidate(agendaDosesProvider);

    navigator.pop(written.length);
  }

  Future<void> _pickDate({
    required int? current,
    required void Function(int?) set,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dayFromMs(current) ?? now,
      firstDate: DateTime(now.year - 5),
      // A dose can be booked ahead, so the picker reaches past today.
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) set(msFromDay(picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.bulkVaccineTitle),
      content: Form(
        key: _formKey,
        // Re-validation on the first keystroke, not only on Save: measured
        // on the phone as a refusal line that outlived the text that fixed it.
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.bulkVaccineCount('${widget.animals.length}'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _vaccineName,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.vaccinationName),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.vaccinationNameRequired
                    : null,
              ),
              const SizedBox(height: 8),
              DateTile(
                label: l10n.vaccinationGiven,
                value: formatDay(context, _administered),
                onPick: () => _pickDate(
                  current: _administered,
                  set: (value) => setState(() => _administered = value),
                ),
              ),
              const SizedBox(height: 8),
              DateTile(
                label: l10n.vaccinationNextDue,
                value: formatDay(context, _nextDue),
                onPick: () => _pickDate(
                  current: _nextDue,
                  set: (value) => setState(() => _nextDue = value),
                ),
                onClear: _nextDue == null
                    ? null
                    : () => setState(() => _nextDue = null),
              ),
              const SizedBox(height: 10),
              // The names, not just a number: a breeder who picked the wrong
              // litter sees it here, before nine rows are in the ledger.
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: <Widget>[
                  for (final animal in widget.animals)
                    Chip(
                      label: Text(animal.name),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.actionSave),
        ),
      ],
    );
  }
}

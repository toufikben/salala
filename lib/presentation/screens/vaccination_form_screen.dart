import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/vaccination.dart';
import '../providers/app_providers.dart';
import '../providers/record_providers.dart';
import '../widgets/date_tile.dart';
import '../widgets/record_refusal.dart';

/// One dose: what was given, when, and when the next one is due.
///
/// The due date is the whole point of the screen — it is what the reminder
/// scheduler and the overdue badge read — so it is a first-class field here
/// rather than a note a breeder would have to re-read by eye.
class VaccinationFormScreen extends ConsumerStatefulWidget {
  const VaccinationFormScreen({
    super.key,
    required this.animalId,
    this.vaccinationId,
  });

  final String animalId;
  final String? vaccinationId;

  bool get isEdit => vaccinationId != null;

  @override
  ConsumerState<VaccinationFormScreen> createState() =>
      _VaccinationFormScreenState();
}

class _VaccinationFormScreenState extends ConsumerState<VaccinationFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _vaccineName;
  late final TextEditingController _manufacturer;
  late final TextEditingController _batchNumber;
  late final TextEditingController _vetName;
  late final TextEditingController _clinicName;
  late final TextEditingController _certificateNumber;

  int? _administered;
  int? _nextDue;

  Vaccination? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _vaccineName = TextEditingController();
    _manufacturer = TextEditingController();
    _batchNumber = TextEditingController();
    _vetName = TextEditingController();
    _clinicName = TextEditingController();
    _certificateNumber = TextEditingController();
    if (!widget.isEdit) {
      _administered = msFromDay(DateTime.now());
    }
  }

  void _fillFrom(Vaccination dose) {
    if (_existing != null) return;
    _existing = dose;
    _vaccineName.text = dose.vaccineName;
    _manufacturer.text = dose.manufacturer ?? '';
    _batchNumber.text = dose.batchNumber ?? '';
    _vetName.text = dose.vetName ?? '';
    _clinicName.text = dose.clinicName ?? '';
    _certificateNumber.text = dose.certificateNumber ?? '';
    _administered = dose.dateAdministered;
    _nextDue = dose.nextDueDate;
  }

  @override
  void dispose() {
    _vaccineName.dispose();
    _manufacturer.dispose();
    _batchNumber.dispose();
    _vetName.dispose();
    _clinicName.dispose();
    _certificateNumber.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    if (refuseRecordBeforeBirth(
      context,
      ref,
      animalId: widget.animalId,
      recordMs: _administered,
    )) {
      return;
    }
    if (measuredDatePrecedesAnchor(
      anchorMs: _administered,
      measuredMs: _nextDue,
    )) {
      // Nothing written, so nothing to undo and the button is still live: a due
      // date behind the dose that earned it never clears, and it would sit in the
      // herd's agenda as overdue forever.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).doseDueBeforeAdministered),
        ),
      );
      return;
    }
    setState(() => _saving = true);

    final base =
        _existing ??
        Vaccination(
          id: '',
          animalId: widget.animalId,
          vaccineName: '',
          dateAdministered: 0,
          createdAt: 0,
          updatedAt: 0,
        );

    final draft = base.copyWith(
      animalId: widget.animalId,
      vaccineName: _vaccineName.text.trim(),
      manufacturer: _manufacturer.text.trim(),
      batchNumber: _batchNumber.text.trim(),
      vetName: _vetName.text.trim(),
      clinicName: _clinicName.text.trim(),
      certificateNumber: _certificateNumber.text.trim(),
      dateAdministered: _administered,
      nextDueDate: _nextDue,
      clearNextDueDate: _nextDue == null,
    );

    final saved = await _write(draft);
    // The form's own words are still in the fields, and the button is live again:
    // a dose that did not land is the screen's to keep open.
    if (saved == null) return;

    try {
      await _syncReminder(saved);
    } catch (error) {
      // The dose is written, and the ledger is the durable copy of a reminder:
      // the next launch rebuilds the alarm from it (see `reminderHorizonDays`).
      // A phone that refuses an alarm is not a save that failed, so this closes
      // the form anyway rather than sitting on a wedged button.
      debugPrint('Reminder after a dose save failed: $error');
    }
    if (mounted) context.pop();
  }

  /// The write on its own, so the screen can tell a refused row from a refused
  /// alarm. Returns nothing when the database said no, having already reset the
  /// button and said so: `_saving` is that button's disable switch, and leaving
  /// it set on a failure would have frozen the form on a dose that is not in the
  /// ledger.
  Future<Vaccination?> _write(Vaccination draft) async {
    try {
      return await saveVaccination(ref, draft);
    } catch (error) {
      debugPrint('Vaccination save failed: $error');
      if (mounted) _refuseSave();
      return null;
    }
  }

  /// A write the database refused. The form stays open with the breeder's words
  /// still in it, so the button has to work again and the screen has to say the
  /// dose did not land rather than look like a save still in progress.
  void _refuseSave() {
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).recordSaveFailed)),
    );
  }

  /// Hands this dose's due date to the operating system.
  ///
  /// Everything is read off `saved`, not off the form: the row in the database
  /// is the one the alarm has to match, and a new dose only learns its id when
  /// the write happened. A dose with no next-due date clears the alarms instead
  /// of scheduling one, which is what `remindersFor` does with a null due date.
  Future<void> _syncReminder(Vaccination dose) async {
    final l10n = AppLocalizations.of(context);
    final scheduler = ref.read(reminderSchedulerProvider);
    if (!reminderAllowedFor(ref, widget.animalId)) {
      // The dose is in the ledger, and the phone is told nothing about it: the
      // next person to wake for this shot lives at another address. Cancelling
      // rather than skipping means a dose edited back onto an animal who is home
      // again cannot leave its old booking stranded.
      await scheduler.cancel(dose.id);
      return;
    }
    await scheduler.replace(
      recordId: dose.id,
      dueMs: dose.nextDueDate,
      l10n: l10n,
      title: reminderTitle(ref, l10n, widget.animalId),
      what: dose.vaccineName,
      dueDay: formatDay(context, dose.nextDueDate),
    );
  }

  Future<void> _delete() async {
    final dose = _existing;
    if (dose == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recordDeleteTitle),
        content: Text(l10n.vaccinationDeleteBody),
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
      await deleteVaccination(ref, dose);
    } catch (error) {
      if (mounted) refuseRecordDelete(context, error);
      return;
    }
    // The row is out of the ledger now, so a failed cancel is not something this
    // screen can undo by retrying, and the launch resync cannot repair it either
    // — that only re-books records the ledger still names. Logged, and the
    // screen closes on a dose that really is gone.
    try {
      await ref.read(reminderSchedulerProvider).cancel(dose.id);
    } catch (error) {
      debugPrint('Alarm cancel after a dose delete failed: $error');
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doses = ref.watch(vaccinationsForAnimalProvider(widget.animalId));

    if (widget.isEdit) {
      final found = (doses.value ?? const <Vaccination>[]).where(
        (v) => v.id == widget.vaccinationId,
      );
      if (found.isNotEmpty) _fillFrom(found.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? l10n.vaccinationEditTitle : l10n.vaccinationAddTitle,
        ),
        actions: <Widget>[
          if (_existing != null)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: widget.isEdit && doses.value == null
          // Editing a dose that has not arrived yet would open an empty form and
          // let a save overwrite the real row with blanks.
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              // SingleChildScrollView + Column, never a lazy ListView:
              // Form.validate() only visits mounted fields.
              child: SingleChildScrollView(
                // Clear of the system navigation bar, which used to clip the Save pill.
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _vaccineName,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationName,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.vaccinationNameRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DateTile(
                      label: l10n.vaccinationGiven,
                      value: formatDay(context, _administered),
                      onPick: () => _pickDate(
                        current: _administered,
                        set: (v) => setState(() => _administered = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DateTile(
                      label: l10n.vaccinationNextDue,
                      value: formatDay(context, _nextDue),
                      onPick: () => _pickDate(
                        current: _nextDue,
                        set: (v) => setState(() => _nextDue = v),
                      ),
                      onClear: _nextDue == null
                          ? null
                          : () => setState(() => _nextDue = null),
                    ),
                    if (_nextDue != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.vaccinationNextDueHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _manufacturer,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationManufacturer,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _batchNumber,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationBatch,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vetName,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationVet,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clinicName,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationClinic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _certificateNumber,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationCertificate,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : () => context.pop(),
                            child: Text(l10n.actionCancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(l10n.actionSave),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

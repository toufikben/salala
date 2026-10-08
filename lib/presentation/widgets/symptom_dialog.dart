import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/symptom.dart';
import '../providers/record_providers.dart';
import 'date_tile.dart';
import 'record_refusal.dart';

/// Opens the same dialog for a new sighting and for correcting an old one.
Future<void> showSymptomDialog(
  BuildContext context, {
  required String animalId,
  Symptom? existing,
}) => showDialog<void>(
  context: context,
  builder: (_) => SymptomDialog(animalId: animalId, existing: existing),
);

/// A sign the breeder saw, typed rather than measured.
///
/// A dialog and not a form screen, because a symptom is recorded in one line
/// ("vomiting, since this morning, mild") and because the answer it changes —
/// the triage card at the top of the ledger — has to still be on screen when the
/// row lands.
///
/// Editing is not a nicety here: the rules read `ongoing`, so the row that made
/// the card alarm is the row that has to be able to stop it. Marking a sighting
/// resolved is how a breeder says "it passed" without deleting the fact that it
/// happened.
class SymptomDialog extends ConsumerStatefulWidget {
  const SymptomDialog({super.key, required this.animalId, this.existing});

  final String animalId;
  final Symptom? existing;

  @override
  ConsumerState<SymptomDialog> createState() => _SymptomDialogState();
}

class _SymptomDialogState extends ConsumerState<SymptomDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _note;
  late SymptomSeverity _severity;
  late int _observedAt;
  late bool _ongoing;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = TextEditingController(text: existing?.label ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _severity = existing?.severity ?? SymptomSeverity.mild;
    _observedAt = existing?.observedAt ?? msFromDay(DateTime.now());
    _ongoing = existing?.ongoing ?? true;
  }

  @override
  void dispose() {
    _label.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final stored = dayFromMs(_observedAt);
    // A row can arrive from a pack written on a phone whose clock was ahead, and
    // the picker rejects an initial date past `lastDate`. Starting from today
    // instead keeps the dialog openable; the date stays stored until someone
    // changes it.
    final initial = stored == null || stored.isAfter(now) ? now : stored;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 15),
      // No future sighting: the rules read the age of a sign, and a
      // tomorrow-dated row would keep an animal off the card until that day.
      lastDate: now,
    );
    if (picked != null) setState(() => _observedAt = msFromDay(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final existing = widget.existing;
    final note = _note.text.trim();
    final symptom =
        (existing ??
                Symptom(
                  id: '',
                  animalId: widget.animalId,
                  label: '',
                  severity: _severity,
                  observedAt: _observedAt,
                  ongoing: _ongoing,
                  createdAt: 0,
                  updatedAt: 0,
                ))
            .copyWith(
              animalId: widget.animalId,
              label: _label.text.trim(),
              severity: _severity,
              observedAt: _observedAt,
              ongoing: _ongoing,
              note: note,
              clearNote: note.isEmpty,
            );

    try {
      await saveSymptom(ref, symptom);
    } catch (error) {
      debugPrint('Symptom save failed: $error');
      if (mounted) _refuseSave();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// A write the database refused. The dialog holds the sighting as typed and the
  /// Save button answers a tap again, so the row that would have changed the
  /// triage card at the top of the ledger can be tried once more.
  void _refuseSave() {
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).recordSaveFailed)),
    );
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recordDeleteTitle),
        content: Text(l10n.symptomDeleteBody),
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
    if (confirmed != true || !mounted) return;
    try {
      await deleteSymptom(ref, existing);
    } catch (error) {
      if (mounted) refuseRecordDelete(context, error);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_isEdit ? l10n.symptomEditTitle : l10n.symptomAddTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _label,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.symptomName),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.symptomNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.symptomSeverity,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              // Chips in a Wrap rather than a segmented control: three severity
              // words have to fit a narrow phone in a language whose words are
              // longer than English's.
              Wrap(
                spacing: 8,
                children: [
                  for (final level in SymptomSeverity.values)
                    ChoiceChip(
                      label: Text(severityLabel(l10n, level)),
                      selected: _severity == level,
                      onSelected: (_) => setState(() => _severity = level),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              DateTile(
                label: l10n.symptomObservedOn,
                value: formatDay(context, _observedAt),
                onPick: _pickDate,
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.symptomOngoing),
                value: _ongoing,
                onChanged: (value) => setState(() => _ongoing = value),
              ),
              TextFormField(
                controller: _note,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.animalNotes),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        if (_isEdit)
          TextButton(
            onPressed: _saving ? null : _delete,
            child: Text(l10n.actionDelete),
          ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}

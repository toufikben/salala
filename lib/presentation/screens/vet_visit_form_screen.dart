import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money.dart';
import '../../data/models/vet_visit.dart';
import '../providers/record_providers.dart';
import '../widgets/date_tile.dart';

/// A consultation: who saw the animal, why, and what came of it.
///
/// Cost is stored as a plain number with the currency the breeder typed, not a
/// converted amount. A placement pack has to show what was spent, not what a
/// fluctuating rate says it is worth today.
class VetVisitFormScreen extends ConsumerStatefulWidget {
  const VetVisitFormScreen({super.key, required this.animalId, this.visitId});

  final String animalId;
  final String? visitId;

  bool get isEdit => visitId != null;

  @override
  ConsumerState<VetVisitFormScreen> createState() => _VetVisitFormScreenState();
}

class _VetVisitFormScreenState extends ConsumerState<VetVisitFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _clinic;
  late final TextEditingController _vet;
  late final TextEditingController _reason;
  late final TextEditingController _outcome;
  late final TextEditingController _cost;
  late final TextEditingController _currency;
  late final TextEditingController _notes;

  int? _visitDate;

  VetVisit? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _clinic = TextEditingController();
    _vet = TextEditingController();
    _reason = TextEditingController();
    _outcome = TextEditingController();
    _cost = TextEditingController();
    _currency = TextEditingController();
    _notes = TextEditingController();
    if (!widget.isEdit) {
      _visitDate = msFromDay(DateTime.now());
    }
  }

  void _fillFrom(VetVisit visit) {
    if (_existing != null) return;
    _existing = visit;
    _clinic.text = visit.clinicName ?? '';
    _vet.text = visit.vetName ?? '';
    _reason.text = visit.reason ?? '';
    _outcome.text = visit.outcome ?? '';
    _cost.text = visit.cost == null ? '' : formatPrice(visit.cost!);
    _currency.text = visit.currency ?? '';
    _notes.text = visit.notes ?? '';
    _visitDate = visit.visitDate;
  }

  @override
  void dispose() {
    _clinic.dispose();
    _vet.dispose();
    _reason.dispose();
    _outcome.dispose();
    _cost.dispose();
    _currency.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dayFromMs(_visitDate) ?? now,
      firstDate: DateTime(now.year - 15),
      // A booked consultation can be dated ahead of today.
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _visitDate = msFromDay(picked));
  }

  double? get _parsedCost {
    final text = _cost.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final base =
        _existing ??
        VetVisit(
          id: '',
          animalId: widget.animalId,
          visitDate: 0,
          createdAt: 0,
          updatedAt: 0,
        );

    await saveVisit(
      ref,
      base.copyWith(
        animalId: widget.animalId,
        clinicName: _clinic.text.trim(),
        vetName: _vet.text.trim(),
        reason: _reason.text.trim(),
        outcome: _outcome.text.trim(),
        cost: _parsedCost,
        clearCost: _parsedCost == null,
        currency: _currency.text.trim().toUpperCase(),
        notes: _notes.text.trim(),
        visitDate: _visitDate,
      ),
    );
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final visit = _existing;
    if (visit == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recordDeleteTitle),
        content: Text(l10n.visitDeleteBody),
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
    await deleteVisit(ref, visit);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visits = ref.watch(visitsForAnimalProvider(widget.animalId));

    if (widget.isEdit) {
      final found = (visits.value ?? const <VetVisit>[]).where(
        (v) => v.id == widget.visitId,
      );
      if (found.isNotEmpty) _fillFrom(found.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? l10n.visitEditTitle : l10n.visitAddTitle),
        actions: <Widget>[
          if (_existing != null)
            IconButton(
              tooltip: l10n.actionDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: widget.isEdit && visits.value == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
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
                    DateTile(
                      label: l10n.visitDate,
                      value: formatDay(context, _visitDate),
                      onPick: _pickDate,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _reason,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: l10n.visitReason),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _outcome,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(labelText: l10n.visitOutcome),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _clinic,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationClinic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vet,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationVet,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _cost,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: l10n.visitCost,
                              hintText: '250',
                            ),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return null;
                              return double.tryParse(
                                        text.replaceAll(',', '.'),
                                      ) ==
                                      null
                                  ? l10n.visitCostInvalid
                                  : null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _currency,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: l10n.visitCurrency,
                              hintText: 'MAD',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notes,
                      minLines: 2,
                      maxLines: 5,
                      decoration: InputDecoration(labelText: l10n.animalNotes),
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

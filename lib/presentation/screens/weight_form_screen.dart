import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/weight.dart';
import '../../data/models/weight_entry.dart';
import '../providers/record_providers.dart';
import '../widgets/date_tile.dart';

/// A weigh-in. Grams are stored, kilograms are typed — the box accepts the
/// number off the scale and converts, because a breeder never weighs a puppy in
/// grams out loud.
class WeightFormScreen extends ConsumerStatefulWidget {
  const WeightFormScreen({super.key, required this.animalId});

  final String animalId;

  @override
  ConsumerState<WeightFormScreen> createState() => _WeightFormScreenState();
}

class _WeightFormScreenState extends ConsumerState<WeightFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _weight = TextEditingController();
  final TextEditingController _note = TextEditingController();

  late int _measuredAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _measuredAt = msFromDay(DateTime.now());
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dayFromMs(_measuredAt) ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) setState(() => _measuredAt = msFromDay(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final grams = parseWeightToGrams(_weight.text);
    if (grams == null) return;
    setState(() => _saving = true);

    await saveWeight(
      ref,
      WeightEntry(
        id: '',
        animalId: widget.animalId,
        weightGrams: grams,
        measuredAt: _measuredAt,
        note: _note.text.trim(),
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weightAdd)),
      body: Form(
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
              TextFormField(
                controller: _weight,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.weightKg,
                  hintText: '4.200',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.weightRequired;
                  }
                  return parseWeightToGrams(value) == null
                      ? l10n.weightInvalid
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DateTile(
                label: l10n.weightMeasuredOn,
                value: formatDay(context, _measuredAt),
                onPick: _pickDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(labelText: l10n.weightNote),
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

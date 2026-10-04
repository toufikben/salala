import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/health_test.dart';
import '../providers/record_providers.dart';
import '../widgets/date_tile.dart';

/// A screening result — hips, eyes, hearing, a cardiac echo — with the certificate
/// number a buyer will one day be shown.
///
/// `validUntil` is what turns the row from a fact into a claim with an expiry:
/// an OFA certification never lapses, a BAER hearing note might.
class HealthTestFormScreen extends ConsumerStatefulWidget {
  const HealthTestFormScreen({super.key, required this.animalId, this.testId});

  final String animalId;
  final String? testId;

  bool get isEdit => testId != null;

  @override
  ConsumerState<HealthTestFormScreen> createState() =>
      _HealthTestFormScreenState();
}

class _HealthTestFormScreenState extends ConsumerState<HealthTestFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _testType;
  late final TextEditingController _result;
  late final TextEditingController _testingBody;
  late final TextEditingController _certificateNo;
  late final TextEditingController _verifiedBy;
  late final TextEditingController _notes;

  int? _testDate;
  int? _validUntil;

  HealthTest? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _testType = TextEditingController();
    _result = TextEditingController();
    _testingBody = TextEditingController();
    _certificateNo = TextEditingController();
    _verifiedBy = TextEditingController();
    _notes = TextEditingController();
    if (!widget.isEdit) {
      _testDate = msFromDay(DateTime.now());
    }
  }

  void _fillFrom(HealthTest test) {
    if (_existing != null) return;
    _existing = test;
    _testType.text = test.testType;
    _result.text = test.result;
    _testingBody.text = test.testingBody ?? '';
    _certificateNo.text = test.certificateNo ?? '';
    _verifiedBy.text = test.verifiedBy ?? '';
    _notes.text = test.notes ?? '';
    _testDate = test.testDate;
    _validUntil = test.validUntil;
  }

  @override
  void dispose() {
    _testType.dispose();
    _result.dispose();
    _testingBody.dispose();
    _certificateNo.dispose();
    _verifiedBy.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required int? current,
    required void Function(int?) onSelect,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: dayFromMs(current) ?? now,
      firstDate: DateTime(now.year - 15),
      // Certificates are issued for the future too ("valid until").
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) onSelect(msFromDay(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final base =
        _existing ??
        HealthTest(
          id: '',
          animalId: widget.animalId,
          testType: '',
          result: '',
          testDate: 0,
          createdAt: 0,
          updatedAt: 0,
        );

    await saveHealthTest(
      ref,
      base.copyWith(
        animalId: widget.animalId,
        testType: _testType.text.trim(),
        result: _result.text.trim(),
        testingBody: _testingBody.text.trim(),
        certificateNo: _certificateNo.text.trim(),
        verifiedBy: _verifiedBy.text.trim(),
        notes: _notes.text.trim(),
        testDate: _testDate,
        validUntil: _validUntil,
        clearValidUntil: _validUntil == null,
      ),
    );
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final test = _existing;
    if (test == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recordDeleteTitle),
        content: Text(l10n.healthTestDeleteBody),
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
    await deleteHealthTest(ref, test);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tests = ref.watch(healthTestsForAnimalProvider(widget.animalId));

    if (widget.isEdit) {
      final found = (tests.value ?? const <HealthTest>[]).where(
        (t) => t.id == widget.testId,
      );
      if (found.isNotEmpty) _fillFrom(found.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEdit ? l10n.healthTestEditTitle : l10n.healthTestAddTitle,
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
      body: widget.isEdit && tests.value == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _testType,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.healthTestType,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.healthTestTypeRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _result,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.healthTestResult,
                        helperText: l10n.healthTestResultHelper,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? l10n.healthTestResultRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DateTile(
                      label: l10n.healthTestDate,
                      value: formatDay(context, _testDate),
                      onPick: () => _pickDate(
                        current: _testDate,
                        onSelect: (v) => setState(() => _testDate = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DateTile(
                      label: l10n.healthTestValidUntil,
                      value: formatDay(context, _validUntil),
                      onPick: () => _pickDate(
                        current: _validUntil,
                        onSelect: (v) => setState(() => _validUntil = v),
                      ),
                      onClear: _validUntil == null
                          ? null
                          : () => setState(() => _validUntil = null),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _testingBody,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.healthTestBody,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _certificateNo,
                      decoration: InputDecoration(
                        labelText: l10n.vaccinationCertificate,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _verifiedBy,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: l10n.healthTestVerifiedBy,
                      ),
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

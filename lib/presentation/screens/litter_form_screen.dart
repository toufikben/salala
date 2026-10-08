import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/gestation.dart';
import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import '../providers/app_providers.dart';
import '../widgets/date_tile.dart';

/// Records a mating and, in the same save, registers its puppies as animals.
///
/// The puppy count is the whole point of this screen: a breeder who has just
/// whelped will not type six near-identical rows, and every animal that skips
/// registration is a vaccination record that will never exist.
class LitterFormScreen extends ConsumerStatefulWidget {
  const LitterFormScreen({super.key});

  @override
  ConsumerState<LitterFormScreen> createState() => _LitterFormScreenState();
}

class _LitterFormScreenState extends ConsumerState<LitterFormScreen> {
  static const int _maxPuppies = 12;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  String? _damId;
  String? _sireId;
  int? _matingDate;
  int? _whelpingDate;
  int? _weaningDate;
  int _puppies = 0;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
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
      firstDate: DateTime(now.year - 6),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) set(msFromDay(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final animals = ref.read(animalsProvider).value ?? const <Animal>[];
    final dam = animals.firstWhere((a) => a.id == _damId);
    final name = _name.text.trim();

    setState(() => _saving = true);

    final litter = Litter(
      id: '',
      name: name,
      damId: dam.id,
      sireId: _sireId,
      matingDate: _matingDate,
      whelpingDate: _whelpingDate,
      weaningDate: _weaningDate,
      notes: _notes.text.trim(),
      createdAt: 0,
      updatedAt: 0,
    );

    final puppies = <Animal>[
      for (var index = 1; index <= _puppies; index++)
        Animal(
          id: '',
          name: '$name $index',
          species: dam.species,
          breed: dam.breed,
          sex: Sex.unknown,
          status: AnimalStatus.active,
          birthDate: _whelpingDate,
          createdAt: 0,
          updatedAt: 0,
        ),
    ];

    try {
      await ref.read(littersProvider.notifier).register(litter, puppies);
    } catch (error) {
      // The litter and its puppies land or do not land together — that is the
      // provider's transaction, not this screen's — so a refusal here means
      // nothing was written and the form is the place to try again.
      debugPrint('Litter registration failed: $error');
      if (mounted) _refuseSave();
      return;
    }

    if (mounted) context.pop();
  }

  /// A write the database refused. The form stays open with the breeder's words
  /// still in it, so the button has to work again and the screen has to say the
  /// litter did not land rather than look like a registration still running.
  void _refuseSave() {
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).recordSaveFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final animals = ref.watch(animalsProvider).value ?? const <Animal>[];
    final dams = animals
        .where((a) => a.isBreedingStock && a.sex == Sex.female)
        .toList(growable: false);
    final sires = animals
        .where((a) => a.isBreedingStock && a.sex == Sex.male)
        .toList(growable: false);
    final damSpecies = animalById(animals, _damId)?.species;
    final expected = expectedWhelpingDate(
      species: damSpecies,
      matingDate: _matingDate,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.litterAddTitle)),
      body: Form(
        key: _formKey,
        // Same reason as the animal form: a lazy ListView unmounts fields
        // outside the cache extent, and Form.validate() skips what is not
        // mounted — so the required checks below would silently pass.
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
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.litterName),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.litterNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _damId,
                decoration: InputDecoration(
                  labelText: l10n.litterDam,
                  helperText: dams.isEmpty ? l10n.litterNoDams : null,
                ),
                items: dams
                    .map(
                      (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _damId = value),
                validator: (value) =>
                    value == null ? l10n.litterDamRequired : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _sireId,
                decoration: InputDecoration(labelText: l10n.litterSire),
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.litterSireUnknown),
                  ),
                  for (final a in sires)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                ],
                onChanged: (value) => setState(() => _sireId = value),
              ),
              const SizedBox(height: 12),
              DateTile(
                label: l10n.litterMatingDate,
                value: _matingDate == null
                    ? null
                    : formatDay(context, _matingDate),
                onPick: () => _pickDate(
                  current: _matingDate,
                  set: (ms) => setState(() => _matingDate = ms),
                ),
                onClear: _matingDate == null
                    ? null
                    : () => setState(() => _matingDate = null),
              ),
              if (expected != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.litterExpected(formatDay(context, expected)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              DateTile(
                label: l10n.litterWhelpingDate,
                value: _whelpingDate == null
                    ? null
                    : formatDay(context, _whelpingDate),
                onPick: () => _pickDate(
                  current: _whelpingDate,
                  set: (ms) => setState(() => _whelpingDate = ms),
                ),
                onClear: _whelpingDate == null
                    ? null
                    : () => setState(() => _whelpingDate = null),
              ),
              const SizedBox(height: 12),
              DateTile(
                label: l10n.litterWeaningDate,
                value: _weaningDate == null
                    ? null
                    : formatDay(context, _weaningDate),
                onPick: () => _pickDate(
                  current: _weaningDate,
                  set: (ms) => setState(() => _weaningDate = ms),
                ),
                onClear: _weaningDate == null
                    ? null
                    : () => setState(() => _weaningDate = null),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _puppies,
                decoration: InputDecoration(
                  labelText: l10n.litterPuppiesToRegister,
                  helperText: l10n.litterPuppiesHint,
                ),
                items: <DropdownMenuItem<int>>[
                  for (var index = 0; index <= _maxPuppies; index++)
                    DropdownMenuItem(value: index, child: Text('$index')),
                ],
                onChanged: (value) =>
                    setState(() => _puppies = value ?? _puppies),
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

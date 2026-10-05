import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../providers/app_providers.dart';
import '../widgets/date_tile.dart';

enum AnimalFormMode { create, edit }

class AnimalFormScreen extends ConsumerStatefulWidget {
  const AnimalFormScreen({super.key, required this.mode, this.animalId});

  final AnimalFormMode mode;
  final String? animalId;

  @override
  ConsumerState<AnimalFormScreen> createState() => _AnimalFormScreenState();
}

class _AnimalFormScreenState extends ConsumerState<AnimalFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _species;
  late final TextEditingController _breed;
  late final TextEditingController _color;
  late final TextEditingController _microchip;
  late final TextEditingController _registrationNo;
  late final TextEditingController _registry;
  late final TextEditingController _notes;

  Sex _sex = Sex.unknown;
  AnimalStatus _status = AnimalStatus.active;
  bool _breedingStock = false;
  int? _birthDate;

  Animal? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _species = TextEditingController();
    _breed = TextEditingController();
    _color = TextEditingController();
    _microchip = TextEditingController();
    _registrationNo = TextEditingController();
    _registry = TextEditingController();
    _notes = TextEditingController();
  }

  void _fillFrom(Animal animal) {
    if (_existing != null) return;
    _existing = animal;
    _name.text = animal.name;
    _species.text = animal.species;
    _breed.text = animal.breed ?? '';
    _color.text = animal.color ?? '';
    _microchip.text = animal.microchipId ?? '';
    _registrationNo.text = animal.registrationNo ?? '';
    _registry.text = animal.registry ?? '';
    _notes.text = animal.notes ?? '';
    _sex = animal.sex;
    _status = animal.status;
    _breedingStock = animal.isBreedingStock;
    _birthDate = animal.birthDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _species.dispose();
    _breed.dispose();
    _color.dispose();
    _microchip.dispose();
    _registrationNo.dispose();
    _registry.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          dayFromMs(_birthDate) ?? DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = msFromDay(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final controller = ref.read(animalsProvider.notifier);
    final base =
        _existing ??
        Animal(
          id: '',
          name: '',
          species: '',
          sex: Sex.unknown,
          status: AnimalStatus.active,
          createdAt: 0,
          updatedAt: 0,
        );

    final draft = base.copyWith(
      name: _name.text.trim(),
      species: _species.text.trim().toLowerCase(),
      breed: _breed.text.trim(),
      color: _color.text.trim(),
      microchipId: _microchip.text.trim(),
      registrationNo: _registrationNo.text.trim(),
      registry: _registry.text.trim(),
      notes: _notes.text.trim(),
      sex: _sex,
      status: _status,
      isBreedingStock: _breedingStock,
      birthDate: _birthDate,
      clearBirthDate: _birthDate == null,
    );

    if (widget.mode == AnimalFormMode.edit) {
      await controller.edit(draft);
    } else {
      await controller.create(draft);
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final animals = ref.watch(animalsProvider).value ?? const <Animal>[];

    if (widget.mode == AnimalFormMode.edit) {
      final match = animals.where((a) => a.id == widget.animalId);
      if (match.isNotEmpty) _fillFrom(match.first);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.mode == AnimalFormMode.create
              ? l10n.animalAddTitle
              : l10n.animalEditTitle,
        ),
      ),
      body: Form(
        key: _formKey,
        // A Column inside a scroll view, deliberately not a ListView: a lazy
        // ListView drops fields outside the cache extent from the tree, and
        // Form.validate() only visits mounted fields — so an animal could be
        // saved with no name just because the name box had scrolled away.
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
                decoration: InputDecoration(labelText: l10n.animalName),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.animalNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _species,
                decoration: InputDecoration(
                  labelText: l10n.animalSpecies,
                  helperText: l10n.animalSpeciesHelper,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.animalSpeciesRequired
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Sex>(
                initialValue: _sex,
                decoration: InputDecoration(labelText: l10n.animalSex),
                items: Sex.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(sexLabel(l10n, s)),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _sex = value ?? _sex),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AnimalStatus>(
                initialValue: _status,
                decoration: InputDecoration(labelText: l10n.animalStatus),
                items: AnimalStatus.values
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(statusLabel(l10n, s)),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
              ),
              const SizedBox(height: 12),
              DateTile(
                value: _birthDate == null
                    ? null
                    : formatDay(context, _birthDate),
                label: l10n.animalBirthDate,
                onPick: _pickBirthDate,
                onClear: _birthDate == null
                    ? null
                    : () => setState(() => _birthDate = null),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _breedingStock,
                title: Text(l10n.animalIsBreedingStock),
                onChanged: (value) => setState(() => _breedingStock = value),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _breed,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.animalBreed),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _color,
                decoration: InputDecoration(labelText: l10n.animalColor),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _microchip,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.animalMicrochip),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _registrationNo,
                decoration: InputDecoration(
                  labelText: l10n.animalRegistrationNo,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _registry,
                decoration: InputDecoration(labelText: l10n.animalRegistry),
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

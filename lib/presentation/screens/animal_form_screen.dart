import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/l10n/enum_labels.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/text_input.dart';
import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import '../../services/reminder_resync.dart';
import '../providers/app_providers.dart';
import '../widgets/date_tile.dart';
import '../widgets/record_refusal.dart';

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
  int? _deathDate;
  int? _microchipDate;

  /// Who this animal came from and which whelping it belongs to.
  ///
  /// Four columns the schema has held since v1 that no screen could write, so a
  /// puppy registered from a litter carried its dam and its litter only because
  /// `createWithPuppies` stamped them, and an animal added by hand carried
  /// neither — for ever, because `copyWith` had no way to write NULL back and
  /// the form had no field to write a value into.
  String? _damId;
  String? _sireId;
  String? _litterId;

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
    _deathDate = animal.deathDate;
    _microchipDate = animal.microchipDate;
    _damId = animal.damId;
    _sireId = animal.sireId;
    _litterId = animal.litterId;
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
      // A year back from today is what this used to open on, and a breeder who
      // tapped Save without touching the calendar filed a phantom birthday 365
      // days early — which is exactly the number the age rules read.
      initialDate: dayFromMs(_birthDate) ?? now,
      firstDate: DateTime(now.year - 30),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = msFromDay(picked));
  }

  Future<void> _pickDeathDate() async {
    final now = DateTime.now();
    // Never before the animal was born, and never in the future: a death is a
    // day that has happened.
    final born = dayFromMs(_birthDate);
    final earliest = born ?? DateTime(now.year - 30);
    final stored = dayFromMs(_deathDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: stored == null || stored.isBefore(earliest) ? now : stored,
      firstDate: earliest,
      lastDate: now,
    );
    if (picked != null) setState(() => _deathDate = msFromDay(picked));
  }

  Future<void> _pickMicrochipDate() async {
    final now = DateTime.now();
    final born = dayFromMs(_birthDate);
    final earliest = born ?? DateTime(now.year - 30);
    final stored = dayFromMs(_microchipDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: stored == null || stored.isBefore(earliest) ? now : stored,
      firstDate: earliest,
      lastDate: now,
    );
    if (picked != null) setState(() => _microchipDate = msFromDay(picked));
  }

  /// One parent's choices: "none", the animals of that sex, and the stored one
  /// even if it no longer fits the filter.
  ///
  /// That last item matters after an edit: an animal whose sex was corrected, or
  /// a dam who died, would otherwise leave `initialValue` naming an id the menu
  /// does not contain — and `DropdownButton` throws on exactly that.
  List<DropdownMenuItem<String?>> _parentItems(
    AppLocalizations l10n,
    List<Animal> animals,
    Sex sex,
    String? selected,
  ) {
    final pool =
        animals.where((a) => a.id != widget.animalId && a.sex == sex).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final missing = selected != null && !pool.any((a) => a.id == selected);
    return <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(value: null, child: Text(l10n.animalNone)),
      ...pool.map(
        (a) => DropdownMenuItem<String?>(value: a.id, child: Text(a.name)),
      ),
      if (missing)
        DropdownMenuItem<String?>(
          value: selected,
          child: Text(l10n.animalGone),
        ),
    ];
  }

  Future<void> _save() async {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      revealRefusedField(form);
      return;
    }
    if (_saving) return;
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
      breed: blankToNull(_breed.text),
      color: blankToNull(_color.text),
      microchipId: blankToNull(_microchip.text),
      registrationNo: blankToNull(_registrationNo.text),
      registry: blankToNull(_registry.text),
      notes: blankToNull(_notes.text),
      sex: _sex,
      status: _status,
      isBreedingStock: _breedingStock,
      birthDate: _birthDate,
      clearBirthDate: _birthDate == null,
      deathDate: _deathDate,
      clearDeathDate: _deathDate == null,
      microchipDate: _microchipDate,
      clearMicrochipDate: _microchipDate == null,
      damId: _damId,
      clearDamId: _damId == null,
      sireId: _sireId,
      clearSireId: _sireId == null,
      litterId: _litterId,
      clearLitterId: _litterId == null,
    );

    // Read before the write rather than after it: the form is popped as soon as
    // the save answers, and a disposed widget's `ref` and `context` say nothing
    // about which language a reminder should be booked in.
    final l10n = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toString();
    final scheduler = ref.read(reminderSchedulerProvider);
    final daos = ref.read(daosProvider);
    final isEdit = widget.mode == AnimalFormMode.edit;

    try {
      if (isEdit) {
        await controller.edit(draft);
      } else {
        await controller.create(draft);
      }
    } catch (error) {
      debugPrint('Animal save failed: $error');
      if (mounted) _refuseSave();
      return;
    }

    // The row is written, so the phone is now the only place an alarm can still
    // be living. An animal edited away from home — sold, or dead — keeps the dose
    // her ledger used to book, and `flutter_local_notifications` re-arms that
    // booking every time the app starts: measured on the phone as a 09:00 message
    // about a dog who sleeps at another address. Reconciling her own records here
    // is what takes it out, and it runs for every edit because the same call
    // refreshes the title of an animal who stayed.
    if (isEdit) {
      try {
        await resyncAnimalReminders(
          scheduler,
          daos: daos,
          animalId: draft.id,
          l10n: l10n,
          dueDayText: (ms) => formatDayFor(localeTag, ms),
        );
      } catch (error) {
        // The animal is saved, which is the part that was asked for. The next
        // launch reads the herd again and takes another run at the alarms, so the
        // failure is said out loud in the log rather than passed off as a failed
        // save — the line the delete path already takes.
        debugPrint('Reminder reconcile after an animal edit failed: $error');
      }
    }

    if (mounted) context.pop();
  }

  /// A write the database refused. The form stays open with the breeder's words
  /// still in it, so the button has to work again and the screen has to say the
  /// animal did not land rather than look like a save still in progress.
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
    final litters = ref.watch(littersProvider).value ?? const <Litter>[];

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
                onChanged: (value) => setState(() {
                  _status = value ?? _status;
                  // A death date with no death is a date the ledger would print
                  // as fact: bringing an animal back to the herd clears it,
                  // rather than leaving a hidden `deceased` date behind.
                  if (_status != AnimalStatus.deceased) _deathDate = null;
                }),
              ),
              if (_status == AnimalStatus.deceased) ...<Widget>[
                const SizedBox(height: 12),
                DateTile(
                  value: _deathDate == null
                      ? null
                      : formatDay(context, _deathDate),
                  label: l10n.animalDeathDate,
                  onPick: _pickDeathDate,
                  onClear: _deathDate == null
                      ? null
                      : () => setState(() => _deathDate = null),
                ),
              ],
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
              DropdownButtonFormField<String?>(
                initialValue: _damId,
                decoration: InputDecoration(labelText: l10n.litterDam),
                items: _parentItems(l10n, animals, Sex.female, _damId),
                onChanged: (value) => setState(() => _damId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _sireId,
                decoration: InputDecoration(labelText: l10n.litterSire),
                items: _parentItems(l10n, animals, Sex.male, _sireId),
                onChanged: (value) => setState(() => _sireId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _litterId,
                decoration: InputDecoration(labelText: l10n.animalLitter),
                items: <DropdownMenuItem<String?>>[
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(l10n.animalNone),
                  ),
                  ...litters.map(
                    (l) => DropdownMenuItem<String?>(
                      value: l.id,
                      child: Text(l.name),
                    ),
                  ),
                  if (_litterId != null &&
                      !litters.any((l) => l.id == _litterId))
                    DropdownMenuItem<String?>(
                      value: _litterId,
                      child: Text(l10n.litterGone),
                    ),
                ],
                onChanged: (value) => setState(() => _litterId = value),
              ),
              const SizedBox(height: 12),
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
              DateTile(
                value: _microchipDate == null
                    ? null
                    : formatDay(context, _microchipDate),
                label: l10n.animalMicrochipDate,
                onPick: _pickMicrochipDate,
                onClear: _microchipDate == null
                    ? null
                    : () => setState(() => _microchipDate = null),
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

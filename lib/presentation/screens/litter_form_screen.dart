import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/text_input.dart';
import '../../core/utils/gestation.dart';
import '../../data/models/animal.dart';
import '../../data/models/litter.dart';
import '../providers/app_providers.dart';
import '../widgets/date_tile.dart';
import '../widgets/record_refusal.dart';

/// Records a mating and, in the same save, registers its puppies as animals.
///
/// The puppy count is the whole point of this screen: a breeder who has just
/// whelped will not type six near-identical rows, and every animal that skips
/// registration is a vaccination record that will never exist.
///
/// The same screen edits a whelping already in the ledger ([litterId]), because
/// the dates it records are the ones the ledger counts from: a typo in the
/// whelping date is every puppy's wrong birthday. Editing does not register
/// puppies — [LitterListScreen]'s add action does that — so a correction cannot
/// silently create animals.
class LitterFormScreen extends ConsumerStatefulWidget {
  const LitterFormScreen({super.key, this.litterId});

  /// Set to edit an existing whelping instead of registering a new one.
  final String? litterId;

  @override
  ConsumerState<LitterFormScreen> createState() => _LitterFormScreenState();
}

class _LitterFormScreenState extends ConsumerState<LitterFormScreen> {
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

  /// The row as it was when the form opened, kept so the save can tell the
  /// database which values are still its own to rewrite.
  Litter? _original;

  /// False until an edit has read its row and filled the fields.
  bool _prefilled = false;

  bool get _isEdit => widget.litterId != null;

  @override
  void initState() {
    super.initState();
    if (!_isEdit) _prefilled = true;
  }

  /// Fills the form from a row already in the ledger.
  ///
  /// Runs inside `build`, before the fields exist: a `DropdownButtonFormField`
  /// reads `initialValue` once, so a prefill after it was built would show the
  /// first menu entry and save it over the breeder's dam. Guarded by
  /// [_prefilled], so it happens exactly once.
  void _prefill(Litter litter) {
    _original = litter;
    _prefilled = true;
    _name.text = litter.name;
    _notes.text = litter.notes ?? '';
    _damId = litter.damId;
    _sireId = litter.sireId;
    _matingDate = litter.matingDate;
    _whelpingDate = litter.whelpingDate;
    _weaningDate = litter.weaningDate;
  }

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
    final form = _formKey.currentState!;
    if (!form.validate()) {
      revealRefusedField(form);
      return;
    }
    if (_saving) return;
    final problem = litterDateProblem(
      matingDateMs: _matingDate,
      whelpingDateMs: _whelpingDate,
      weaningDateMs: _weaningDate,
    );
    if (problem != LitterDateProblem.none) {
      _refuseDates(problem);
      return;
    }
    final animals = ref.read(animalsProvider).value ?? const <Animal>[];
    final name = _name.text.trim();
    final notes = blankToNull(_notes.text);

    setState(() => _saving = true);

    try {
      if (_isEdit) {
        // Every nullable field is written explicitly, cleared or not: `copyWith`
        // treats "not passed" as "leave it", so a date the breeder cleared would
        // come back the next time the screen opened.
        final original = _original!;
        await ref
            .read(littersProvider.notifier)
            .edit(
              original.copyWith(
                name: name,
                damId: _damId,
                sireId: _sireId,
                clearSireId: _sireId == null,
                matingDate: _matingDate,
                clearMatingDate: _matingDate == null,
                whelpingDate: _whelpingDate,
                clearWhelpingDate: _whelpingDate == null,
                weaningDate: _weaningDate,
                clearWeaningDate: _weaningDate == null,
                notes: notes,
                clearNotes: notes == null,
              ),
              previous: original,
            );
      } else {
        final dam = animals.firstWhere((a) => a.id == _damId);

        final litter = Litter(
          id: '',
          name: name,
          damId: dam.id,
          sireId: _sireId,
          matingDate: _matingDate,
          whelpingDate: _whelpingDate,
          weaningDate: _weaningDate,
          notes: notes,
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

        await ref.read(littersProvider.notifier).register(litter, puppies);
      }
    } catch (error) {
      // The litter and its puppies land or do not land together — that is the
      // provider's transaction, not this screen's — so a refusal here means
      // nothing was written and the form is the place to try again.
      debugPrint('Litter save failed: $error');
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

  /// Dates that cannot both have happened. Refused before the write rather than
  /// corrected later, because every puppy's birthday is copied from the whelping
  /// date, so a slipped pair becomes the herd's age arithmetic and the litter's
  /// PDF prints the two dates side by side. The edit screen makes the refusal
  /// more important, not less: a corrected row is saved over the old one, and the
  /// old dates are not kept anywhere to fall back to.
  void _refuseDates(LitterDateProblem problem) {
    final l10n = AppLocalizations.of(context);
    // Exhaustive on purpose: a third rule added to the enum has to be answered
    // here, rather than falling into whichever sentence this arm happens to be.
    final message = switch (problem) {
      LitterDateProblem.whelpingBeforeMating => l10n.litterWhelpingBeforeMating,
      LitterDateProblem.weaningBeforeWhelping =>
        l10n.litterWeaningBeforeWhelping,
      LitterDateProblem.none => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final animals = ref.watch(animalsProvider).value ?? const <Animal>[];
    final littersAsync = ref.watch(littersProvider);

    // An edit reads a row that may still be on its way (a notification or a
    // deep link opens this screen before the list does). Showing the form first
    // would show it empty, and a Save pressed in that moment would write the
    // blanks over the whelping — so the screen waits, then fills, then shows.
    if (!_prefilled) {
      final litters = littersAsync.value ?? const <Litter>[];
      final matches = litters.where((l) => l.id == widget.litterId);
      if (matches.isEmpty) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.litterEditTitle)),
          body: Center(
            child: littersAsync.isLoading
                ? const CircularProgressIndicator()
                // A read that failed is not a deleted whelping: saying "deleted"
                // over a database error would have the breeder believe her record
                // is gone and register it again.
                : littersAsync.hasError
                ? FilledButton(
                    onPressed: () =>
                        ref.read(littersProvider.notifier).refresh(),
                    child: Text(l10n.actionRetry),
                  )
                : Text(l10n.litterGone),
          ),
        );
      }
      _prefill(matches.first);
    }

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
      appBar: AppBar(
        title: Text(_isEdit ? l10n.litterEditTitle : l10n.litterAddTitle),
      ),
      body: Form(
        key: _formKey,
        // Re-validation on the first keystroke, not only on Save: measured
        // on the phone as a refusal line that outlived the text that fixed it.
        autovalidateMode: AutovalidateMode.onUserInteraction,
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
                items: <DropdownMenuItem<String>>[
                  for (final a in dams)
                    DropdownMenuItem(value: a.id, child: Text(a.name)),
                  // An existing whelping can name a dam who is no longer marked
                  // as breeding stock, or who has died. The menu has to carry
                  // her id all the same: `DropdownButton` throws when
                  // `initialValue` names an item it does not hold, which would
                  // make the whelping impossible to open, let alone correct.
                  if (_damId != null && !dams.any((a) => a.id == _damId))
                    DropdownMenuItem(
                      value: _damId!,
                      child: Text(
                        animalById(animals, _damId)?.name ??
                            l10n.litterDamMissing,
                      ),
                    ),
                ],
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
                  if (_sireId != null && !sires.any((a) => a.id == _sireId))
                    DropdownMenuItem(
                      value: _sireId,
                      child: Text(
                        animalById(animals, _sireId)?.name ?? l10n.animalGone,
                      ),
                    ),
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
              // Only on a new whelping: a correction must not create animals,
              // and adding puppies later is a separate action on the litter
              // screen that knows how many are already registered.
              if (!_isEdit) ...<Widget>[
                DropdownButtonFormField<int>(
                  initialValue: _puppies,
                  decoration: InputDecoration(
                    labelText: l10n.litterPuppiesToRegister,
                    helperText: l10n.litterPuppiesHint,
                  ),
                  items: <DropdownMenuItem<int>>[
                    for (var index = 0; index <= maxPuppiesPerLitter; index++)
                      DropdownMenuItem(value: index, child: Text('$index')),
                  ],
                  onChanged: (value) =>
                      setState(() => _puppies = value ?? _puppies),
                ),
                const SizedBox(height: 12),
              ],
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

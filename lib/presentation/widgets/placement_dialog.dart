import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/text_input.dart';
import '../../core/utils/money.dart';
import '../../data/db/daos.dart';
import '../../data/models/animal.dart';
import '../../data/models/buyer.dart';
import '../../data/models/placement.dart';
import '../../services/contract_files.dart';
import '../../services/reminder_resync.dart';
import '../../services/reminder_scheduler.dart';
import '../../services/trial.dart';
import '../providers/app_providers.dart';
import '../providers/record_providers.dart';
import 'buyer_dialog.dart';
import 'date_tile.dart';
import 'pro_gate.dart';
import 'record_refusal.dart';

/// Opens the same form for a new handover and for correcting an old one.
Future<void> showPlacementDialog(
  BuildContext context, {
  required String animalId,
  Placement? existing,
}) => showDialog<void>(
  context: context,
  builder: (_) => PlacementDialog(animalId: animalId, existing: existing),
);

/// Who the animal went to, when, and on what terms.
///
/// A dialog rather than a form screen because it is the ledger's last row and
/// because the record it fills — the buyer block of the transfer pack — is made
/// on the same screen the pack is exported from. The DAO and the PDF have read
/// placements since the first schema; until this form nothing ever wrote one, so
/// the block came out empty on every document a breeder handed over.
///
/// Nothing here is required. A handover is often half-known at the gate: the
/// buyer's name today, the deposit next week, the guarantee once it is signed.
/// Every column the schema leaves nullable the form leaves blankable, and the
/// pack prints what exists and says "not recorded" for the rest.
class PlacementDialog extends ConsumerStatefulWidget {
  const PlacementDialog({super.key, required this.animalId, this.existing});

  final String animalId;
  final Placement? existing;

  @override
  ConsumerState<PlacementDialog> createState() => _PlacementDialogState();
}

class _PlacementDialogState extends ConsumerState<PlacementDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _price;
  late final TextEditingController _currency;
  late final TextEditingController _guarantee;
  late final TextEditingController _notes;
  late String? _buyerId;
  // The contact this dialog created itself, held next to its id.
  //
  // `saveBuyer` invalidates the list rather than editing it, so the row the DAO
  // just wrote is not necessarily in the choices yet — that reload needs real
  // time on the database isolate. A handover saved in the same breath as the
  // name was typed would otherwise carry no buyer at all, and the buyer's
  // document is the one place the name has to appear. Checking with SQLite
  // instead would put an `await` before `savePlacement(ref, …)`, which is the
  // pattern D7 forbids.
  Buyer? _createdBuyer;
  late int? _placedDate;
  bool _saving = false;

  /// The contract this form is holding: the file name to store, or null.
  ///
  /// Three states, deliberately not two. `_contractName == null` and
  /// `_pickedContract != null` is "a new file was chosen but not yet written";
  /// both null and no existing row is "no contract"; and a name carried from
  /// `existing` is "the row already had one". Storing the bytes on Save rather
  /// than on pick is what keeps a backed-out form from leaving a file on the
  /// disk that no row names.
  late String? _contractName;
  PickedContract? _pickedContract;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _price = TextEditingController(
      text: existing?.price == null ? '' : formatPrice(existing!.price!),
    );
    _currency = TextEditingController(text: existing?.currency ?? '');
    _guarantee = TextEditingController(text: existing?.guaranteeTerms ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _buyerId = existing?.buyerId;
    // Today for a new row, because a placement written at the gate is about
    // today. A row that arrived without a date keeps that absence.
    _placedDate = existing?.placedDate ?? msFromDay(DateTime.now());
    _contractName = existing?.contractFilePath;
  }

  @override
  void dispose() {
    _price.dispose();
    _currency.dispose();
    _guarantee.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? get _parsedPrice {
    final text = _price.text.trim();
    if (text.isEmpty) return null;
    return parsePrice(text);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final stored = dayFromMs(_placedDate);
    // A row can arrive from a pack written on a phone whose clock was ahead, and
    // the picker rejects an initial date past `lastDate`. Starting from today
    // keeps the form openable; the date stays stored until someone changes it.
    final initial = stored == null || stored.isAfter(now) ? now : stored;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 15),
      // A handover is often booked: the litter that goes to a waiting family
      // next month is dated as soon as the family is named.
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) setState(() => _placedDate = msFromDay(picked));
  }

  Future<void> _addBuyer() async {
    final result = await showBuyerDialog(context);
    final created = result?.buyer;
    if (created == null || !mounted) return;
    setState(() {
      _buyerId = created.id;
      _createdBuyer = created;
    });
  }

  /// Correcting the contact this form has chosen — and dropping the choice if
  /// that contact is gone when the form closes.
  ///
  /// The contact form can delete the row it opened on. `_buyerId` is this form's
  /// own string and `_createdBuyer` is a snapshot of a write it did itself, so
  /// without this the Save below still means to name a person the ledger no
  /// longer has: the foreign key refuses it, and the form answers "this could not
  /// be saved" to a handover whose only fault is a name the breeder just took
  /// out — with nothing left to correct, because the name they would remove is
  /// already gone. The answer comes from the dialog rather than from the loaded
  /// list, which is reloaded on another isolate and still names the deleted
  /// contact for a moment after it closes.
  Future<void> _editBuyer(Buyer selected) async {
    final result = await showBuyerDialog(context, existing: selected);
    if (result?.deletedId == null || !mounted) return;
    setState(() {
      _buyerId = null;
      if (_createdBuyer?.id == selected.id) _createdBuyer = null;
    });
  }

  /// The contract the breeder chose, not yet written.
  ///
  /// The bytes are held in memory until Save. Writing on pick would leave a file
  /// on this phone that no row names the moment the breeder backs out, and the
  /// sweep that keeps the folder honest is written against pictures, not
  /// contracts.
  ///
  /// The size is checked here as well as in `store`, because a breeder who
  /// tapped a video by accident should be told at the moment of the mistake
  /// rather than after filling in a price and a guarantee.
  Future<void> _pickContract() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Before the file picker: a breeder who chose a contract and then met a wall
    // has been asked to do work the app would not keep.
    if (!await ensurePro(context, ref, ProFeature.contracts)) return;
    final PickedContract? chosen;
    try {
      chosen = await ref.read(contractFilesProvider).pick();
    } catch (error) {
      debugPrint('Contract file could not be opened: $error');
      messenger.showSnackBar(SnackBar(content: Text(l10n.contractPickFailed)));
      return;
    }
    if (chosen == null || !mounted) return;
    if (chosen.length > maxContractBytes) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.contractTooLarge)));
      return;
    }
    setState(() => _pickedContract = chosen);
  }

  /// Removes the attached contract, on Save rather than on tap.
  ///
  /// A breeder who removes the wrong file and then backs out has removed
  /// nothing: the row still points at it, and the bytes are still there.
  void _clearContract() {
    setState(() {
      _pickedContract = null;
      _contractName = null;
    });
  }

  Future<void> _save() async {
    final form = _formKey.currentState!;
    if (!form.validate()) {
      revealRefusedField(form);
      return;
    }
    if (_saving) return;
    if (refuseRecordBeforeBirth(
      context,
      ref,
      animalId: widget.animalId,
      recordMs: _placedDate,
    )) {
      return;
    }
    setState(() => _saving = true);

    // Read before the write: the dialog pops as soon as it answers, and a
    // disposed widget's `ref` and `context` say nothing about which language the
    // animal's remaining alarms should be booked in.
    final l10n = AppLocalizations.of(context);
    final localeTag = Localizations.localeOf(context).toString();
    final scheduler = ref.read(reminderSchedulerProvider);
    final daos = ref.read(daosProvider);

    final existing = widget.existing;
    final buyers = ref.read(buyersProvider).value ?? const <Buyer>[];
    // Read before the write for the same reason the language is: the farewell
    // sentence needs the animal's own name and the dialog is about to be gone.
    final animals = ref.read(animalsProvider).value ?? const <Animal>[];
    final animalName = animalById(animals, widget.animalId)?.name;
    final messenger = ScaffoldMessenger.of(context);
    // The loaded list, or the contact this dialog wrote a moment ago. An id
    // neither answers to is dropped rather than written, so a buyer deleted
    // while this form was open still cannot become a dangling foreign key.
    final known = _createdBuyer != null && _createdBuyer!.id == _buyerId
        ? _createdBuyer
        : buyerById(buyers, _buyerId);
    final guarantee = blankToNull(_guarantee.text);
    final notes = blankToNull(_notes.text);
    final currency = blankToNull(_currency.text)?.toUpperCase();

    // The contract is written before the row, never after: a row that names a
    // file nobody wrote is a handover whose document is a dead link, and the
    // screen would promise a contract it cannot open. A refused write is a
    // refused save, and the form stays open with everything typed in it.
    final contractFiles = ref.read(contractFilesProvider);
    var contractName = _contractName;
    final picked = _pickedContract;
    if (picked != null) {
      try {
        contractName = await contractFiles.store(widget.animalId, picked);
      } on ContractRefused catch (refused) {
        debugPrint('Contract refused: $refused');
        if (!mounted) return;
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.contractTooLarge)),
        );
        return;
      } catch (error) {
        debugPrint('Contract could not be written: $error');
        if (!mounted) return;
        setState(() => _saving = false);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.recordSaveFailed)),
        );
        return;
      }
    }
    // The file this row used to name, removed after the new row holds. Kept
    // until then so a save that fails leaves the old contract readable.
    final staleContract = existing?.contractFilePath != null &&
            existing!.contractFilePath != contractName
        ? existing.contractFilePath!
        : null;

    // Written whole instead of copied: `Placement.copyWith` can blank a price and
    // nothing else, and clearing a buyer or a date is a real edit here. The id
    // saved is one a row on this phone answers to.
    final placement = Placement(
      id: existing?.id ?? '',
      animalId: widget.animalId,
      buyerId: known?.id,
      placedDate: _placedDate,
      price: _parsedPrice,
      currency: currency,
      guaranteeTerms: guarantee,
      contractFilePath: contractName,
      notes: notes,
      createdAt: existing?.createdAt ?? 0,
      updatedAt: existing?.updatedAt ?? 0,
    );

    try {
      await savePlacement(ref, placement);
    } catch (error) {
      debugPrint('Placement save failed: $error');
      // The file just written is now the file no row names. Put the row back the
      // way it was, which is the state the breeder is looking at.
      if (picked != null && contractName != null) {
        await _discardQuietly(contractFiles, widget.animalId, contractName);
      }
      if (mounted) _refuseSave();
      return;
    }
    if (staleContract != null) {
      await _discardQuietly(contractFiles, widget.animalId, staleContract);
    }
    if (!mounted) return;
    Navigator.of(context).pop();

    // The one warm sentence in the app that is about a leaving, and it is said
    // after the form is gone rather than inside it: a note pinned to the form is
    // a note about the form, and this is about the animal. The record stays —
    // that is the half a breeder needs to hear, because a handover reads like a
    // deletion and is not one. Silence for a correction: the breeder who fixed a
    // price did not send the dog anywhere.
    if (!_isEdit && animalName != null && animalName.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.placedFarewell(animalName))),
      );
    }

    // The save may have marked the animal sold, and a sold animal's alarms are
    // the phone's copy of a booking she no longer owns. Reconciled after the form
    // is gone rather than in front of it: this dialog is the only path that writes
    // a handover, so the animal form's own resync cannot know it happened, but a
    // breeder closing a form should not wait for five reads of the ledger. Every
    // handle below was read before the write, so nothing here touches a disposed
    // widget.
    unawaited(
      _reconcileReminders(scheduler, daos, l10n, localeTag, widget.animalId),
    );
  }

  /// A contract file whose row no longer names it, removed without a word.
  ///
  /// A file this app cannot delete is not a failed save: the row is written, the
  /// breeder's handover is recorded, and what is left behind is a few hundred
  /// kilobytes no screen reaches. Saying so would turn a housekeeping failure into
  /// a message about her ledger.
  static Future<void> _discardQuietly(
    ContractFiles files,
    String animalId,
    String fileName,
  ) async {
    try {
      await files.delete(animalId, fileName);
    } catch (error) {
      debugPrint('Contract $fileName not removed: $error');
    }
  }

  static Future<void> _reconcileReminders(
    ReminderScheduler scheduler,
    Daos daos,
    AppLocalizations l10n,
    String localeTag,
    String animalId,
  ) async {
    try {
      await resyncAnimalReminders(
        scheduler,
        daos: daos,
        animalId: animalId,
        l10n: l10n,
        dueDayText: (ms) => formatDayFor(localeTag, ms),
      );
    } catch (error) {
      // The handover is saved, which is what was asked for. The next launch
      // reads the herd again and takes another run at the alarms.
      debugPrint('Reminder reconcile after a placement save failed: $error');
    }
  }

  /// A write the database refused. The dialog stays open with the handover as
  /// typed, because the alternative is a button that stopped answering over a
  /// placement that never reached the ledger.
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
        content: Text(l10n.placementDeleteBody),
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
      await deletePlacement(ref, existing);
    } catch (error) {
      if (mounted) refuseRecordDelete(context, error);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// The contact field and its two controls.
  ///
  /// A dropdown because contacts are reused — the same family takes the second
  /// litter — and an add button because the person at the door is usually named
  /// for the first time exactly here. The pencil only appears once a buyer is
  /// chosen: a wrong phone number is the one mistake that reaches the document.
  Widget _buyerField(
    AppLocalizations l10n,
    List<Buyer> buyers,
    Buyer? selected,
  ) => Row(
    children: <Widget>[
      Expanded(
        child: DropdownButtonFormField<String?>(
          // Re-keyed on the value rather than driven by it: the field holds
          // its own state, so a buyer created two dialogs ago — an id this
          // form only learns when the contact list refreshes — has to be
          // handed in as the initial value of a fresh one.
          key: ValueKey<String?>(selected?.id),
          initialValue: selected?.id,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.placementBuyer),
          items: <DropdownMenuItem<String?>>[
            DropdownMenuItem(value: null, child: Text(l10n.placementNoBuyer)),
            for (final buyer in buyers)
              DropdownMenuItem(value: buyer.id, child: Text(buyer.name)),
          ],
          onChanged: (value) => setState(() => _buyerId = value),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.person_add_alt),
        tooltip: l10n.buyerAdd,
        onPressed: _saving ? null : _addBuyer,
      ),
      if (selected != null)
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: l10n.buyerEditTitle,
          onPressed: _saving ? null : () => _editBuyer(selected),
        ),
    ],
  );

  /// The attachment row: what is on file, or the two ways to add one.
  ///
  /// One row rather than a picker and a preview: a contract is a single document
  /// and the form has one place for it. When something is attached the row says
  /// what, and offers removal — a breeder who attached the wrong scan has no
  /// other door out of the mistake.
  Widget _contractRow(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final picked = _pickedContract;
    final attached = picked?.name ?? _contractName;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        attached == null
            ? Icons.attach_file_outlined
            : Icons.description_outlined,
        color: attached == null
            ? theme.colorScheme.onSurfaceVariant
            : theme.colorScheme.primary,
      ),
      title: Text(
        attached == null ? l10n.contractAttach : l10n.contractAttached,
      ),
      // The picked file's own name is shown; a name carried from an older row is
      // shown as the file the app wrote, which is a timestamp rather than a
      // document title. The subtitle says which of the two the breeder is
      // looking at, because "contract.pdf" and "1770000000000-48213.pdf" mean
      // different things about where it came from.
      subtitle: attached == null
          ? null
          : Text(
              picked?.name ?? l10n.contractStoredName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: attached == null
          ? null
          : IconButton(
              tooltip: l10n.contractRemove,
              icon: const Icon(Icons.close),
              onPressed: _saving ? null : _clearContract,
            ),
      // Tapping the row again replaces the document. A breeder who attached the
      // wrong scan should not have to remove it first to find that out.
      onTap: _saving ? null : _pickContract,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Watched, not read: a buyer created from this dialog invalidates the list,
    // and the new contact has to appear in these very choices (D26).
    final buyers = ref.watch(buyersProvider).value ?? const <Buyer>[];
    final selected = buyerById(buyers, _buyerId);

    return AlertDialog(
      title: Text(_isEdit ? l10n.placementEditTitle : l10n.placementAddTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          // Re-validation on the first keystroke, not only on Save: measured
          // on the phone as a refusal line that outlived the text that fixed it.
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buyerField(l10n, buyers, selected),
              DateTile(
                label: l10n.placementDate,
                value: formatDay(context, _placedDate),
                onPick: _pickDate,
                onClear: _placedDate == null
                    ? null
                    : () => setState(() => _placedDate = null),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.placementPrice,
                        hintText: '2500',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        return parsePrice(text) == null
                            ? l10n.placementPriceInvalid
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
                        labelText: l10n.placementCurrency,
                        hintText: 'MAD',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _guarantee,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.placementGuarantee),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.animalNotes),
              ),
              const SizedBox(height: 4),
              _contractRow(l10n),
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

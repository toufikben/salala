import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money.dart';
import '../../data/models/buyer.dart';
import '../../data/models/placement.dart';
import '../providers/record_providers.dart';
import 'buyer_dialog.dart';
import 'date_tile.dart';
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
    final created = await showBuyerDialog(context);
    if (created == null || !mounted) return;
    setState(() {
      _buyerId = created.id;
      _createdBuyer = created;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final existing = widget.existing;
    final buyers = ref.read(buyersProvider).value ?? const <Buyer>[];
    // The loaded list, or the contact this dialog wrote a moment ago. An id
    // neither answers to is dropped rather than written, so a buyer deleted
    // while this form was open still cannot become a dangling foreign key.
    final known = _createdBuyer != null && _createdBuyer!.id == _buyerId
        ? _createdBuyer
        : buyerById(buyers, _buyerId);
    final guarantee = _guarantee.text.trim();
    final notes = _notes.text.trim();
    final currency = _currency.text.trim().toUpperCase();

    // Written whole instead of copied: `Placement.copyWith` can blank a price and
    // nothing else, and clearing a buyer or a date is a real edit here. The id
    // saved is one a row on this phone answers to.
    final placement = Placement(
      id: existing?.id ?? '',
      animalId: widget.animalId,
      buyerId: known?.id,
      placedDate: _placedDate,
      price: _parsedPrice,
      currency: currency.isEmpty ? null : currency,
      guaranteeTerms: guarantee.isEmpty ? null : guarantee,
      // No file picker in this form, so a contract path a pack brought in
      // survives the edit rather than being blanked by it.
      contractFilePath: existing?.contractFilePath,
      notes: notes.isEmpty ? null : notes,
      createdAt: existing?.createdAt ?? 0,
      updatedAt: existing?.updatedAt ?? 0,
    );

    try {
      await savePlacement(ref, placement);
    } catch (error) {
      debugPrint('Placement save failed: $error');
      if (mounted) _refuseSave();
      return;
    }
    if (mounted) Navigator.of(context).pop();
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
          onPressed: _saving
              ? null
              : () => showBuyerDialog(context, existing: selected),
        ),
    ],
  );

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../data/models/buyer.dart';
import '../providers/record_providers.dart';
import 'record_refusal.dart';

/// Opens the contact form for a new buyer and for correcting one already chosen.
///
/// The saved buyer comes back rather than nothing, because the placement form
/// that asked for a contact has to select the id the dao just assigned.
Future<Buyer?> showBuyerDialog(BuildContext context, {Buyer? existing}) =>
    showDialog<Buyer>(
      context: context,
      builder: (_) => BuyerDialog(existing: existing),
    );

/// The person an animal went home with.
///
/// A contact, not a customer record: the four things a breeder can answer at the
/// door. Nothing else is asked, because every extra field is one the buyer's
/// document would then have a blank line for.
class BuyerDialog extends ConsumerStatefulWidget {
  const BuyerDialog({super.key, this.existing});

  final Buyer? existing;

  @override
  ConsumerState<BuyerDialog> createState() => _BuyerDialogState();
}

class _BuyerDialogState extends ConsumerState<BuyerDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _country;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _phone = TextEditingController(text: existing?.phone ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _country = TextEditingController(text: existing?.countryCode ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _country.dispose();
    super.dispose();
  }

  /// A blank contact line is stored as absent, not as an empty string: the
  /// transfer pack prints a phone row only when the phone is there, so `''` would
  /// put an empty "Phone:" on a document a buyer keeps.
  static String? _trimmed(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);

    final existing = widget.existing;
    final saved = await _write(existing);
    if (saved == null) return;
    if (mounted) Navigator.of(context).pop(saved);
  }

  /// The write on its own, so the dialog can tell a refused row from a saved
  /// contact: `_saving` is the Save button's disable switch, and leaving it set
  /// after a refusal would have frozen the dialog on a buyer who is not in the
  /// ledger. Returns nothing when the database said no, having already put the
  /// button back and said so.
  Future<Buyer?> _write(Buyer? existing) async {
    try {
      return await saveBuyer(
        ref,
        Buyer(
          id: existing?.id ?? '',
          name: _name.text.trim(),
          phone: _trimmed(_phone),
          email: _trimmed(_email),
          countryCode: _trimmed(_country)?.toUpperCase(),
          createdAt: existing?.createdAt ?? 0,
          updatedAt: existing?.updatedAt ?? 0,
        ),
      );
    } catch (error) {
      debugPrint('Buyer save failed: $error');
      if (mounted) _refuseSave();
      return null;
    }
  }

  /// A write the database refused. The dialog keeps the contact as typed, the Save
  /// button answers a tap again, and the breeder hears that nothing landed — a
  /// handover document that names a buyer who is not in the ledger is the one
  /// thing this dialog must not quietly produce.
  void _refuseSave() {
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).recordSaveFailed)),
    );
  }

  /// Removing the contact, which is a different act from correcting it.
  ///
  /// The row deleted is the one the ledger holds ([BuyerDialog.existing]), not the
  /// text in these boxes: a name half-retyped cannot be deleted, and the breeder
  /// would hear "not there" about a person who is. The dialog then closes without a
  /// result, so the placement form that opened it keeps whatever else it was
  /// holding and simply loses this choice.
  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recordDeleteTitle),
        content: Text(l10n.buyerDeleteBody(existing.name)),
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
    setState(() => _saving = true);

    try {
      await deleteBuyer(ref, existing);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        refuseRecordDelete(context, error);
      }
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_isEdit ? l10n.buyerEditTitle : l10n.buyerAddTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          // A scrolled column, never a lazy list: `Form.validate()` only visits
          // mounted fields, so a name outside the cache extent would go unasked
          // and a buyer with no name would be written (D11).
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // The label and its refusal are the animal form's. Every screen
              // here asks for a name in the same words, and they are already
              // carried in three languages — the same reason the note fields all
              // read `animalNotes`.
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
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: l10n.buyerPhone),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(labelText: l10n.buyerEmail),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _country,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.buyerCountryCode,
                  hintText: 'MA',
                ),
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

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// A read-only date field that opens the picker on tap.
///
/// Extracted from the animal form because a litter carries three of these
/// (mating, whelping, weaning) and each one has to be clearable — a breeder who
/// mis-taps a date must be able to undo it without editing the row in a dump.
class DateTile extends StatelessWidget {
  const DateTile({
    super.key,
    required this.label,
    required this.value,
    required this.onPick,
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      // The whole outlined box, calendar icon included, is the control. With the
      // tap area confined to the value text, the icon — the thing that reads as
      // "press me" — did nothing on a real phone.
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_today_outlined)
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: l10n.actionClear,
                  onPressed: onClear,
                ),
        ),
        isEmpty: value == null,
        child: Text(value ?? ''),
      ),
    );
  }
}

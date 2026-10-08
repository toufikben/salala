import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';

/// A delete the database refused, said out loud.
///
/// The row is still in the ledger after this, which is the whole reason the
/// sentence is different from the save one: a Delete button that quietly did
/// nothing reads to a breeder as a record that is gone, and the two ways to
/// correct that — saying nothing, or saying it wrongly — both cost the ledger
/// its credibility. The screen stays exactly where it was, because the record
/// it is showing is still true.
///
/// The caller has to hold a live `BuildContext` (D33's split: this runs after
/// the await, so a dialog the breeder dismissed in the meantime is not here to
/// be told anything).
void refuseRecordDelete(BuildContext context, Object error) {
  debugPrint('Record delete refused: $error');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).recordDeleteFailed)),
  );
}

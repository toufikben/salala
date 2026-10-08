import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../providers/app_providers.dart';

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

/// A record dated before the animal it belongs to was born, refused on the spot.
///
/// Returns whether it refused, so the form's `_save` reads as a guard rather
/// than as a control-flow puzzle. It says its own sentence instead of sharing
/// [refuseRecordDelete]'s, because the two refusals mean opposite things to the
/// breeder: one is "the database would not take this, try again", the other is
/// "this date cannot be right, change it" — and a message that says try again
/// when the answer is to change the year teaches the breeder to tap Save twice.
///
/// Runs before anything is written, on the animal as the ledger holds it at that
/// moment rather than as the form loaded it, so an animal whose birth date was
/// corrected on another screen while this form was open cannot be judged against
/// the stale value. An animal with no birth date records anything: the absence is
/// the breeder's not-yet-known fact, and refusing a date against it would make
/// the unknown cost more than the wrong answer.
bool refuseRecordBeforeBirth(
  BuildContext context,
  WidgetRef ref, {
  required String animalId,
  required int? recordMs,
}) {
  final animals = ref.read(animalsProvider).value ?? const <Animal>[];
  if (!recordPrecedesBirth(
    recordMs: recordMs,
    birthMs: animalById(animals, animalId)?.birthDate,
  )) {
    return false;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).recordDateBeforeBirth)),
  );
  return true;
}

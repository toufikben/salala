import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/animal.dart';
import '../providers/app_providers.dart';

/// The field a validation refusal turned down, brought back where she is looking.
///
/// Measured on the phone and not guessed: with the animal form scrolled to its
/// Save pill, tapping Save with the species box empty left the screen
/// byte-identical before and after the tap. The error text did appear — under
/// the box, at the top of a form taller than the screen, in the part of it the
/// breeder had scrolled away from. A widget test could never have read that,
/// because `find.text` answers for a widget in the tree, not for one a person
/// can see.
///
/// So a form that refuses has to answer in the place the breeder is looking at:
/// the first box that said no is scrolled into view. Nothing is said out loud
/// here, because the box carries its own sentence once she can see it, and a
/// snackbar on top of that would be two voices naming one problem.
void revealRefusedField(FormState form) {
  final field = _firstRefusedField(form.context);
  if (field == null) return;
  Scrollable.ensureVisible(
    field,
    // Not centred: enough clearance to read the error line under the box, and
    // close enough that the fields around it stay legible for context.
    alignment: 0.1,
    duration: const Duration(milliseconds: 200),
    curve: Curves.easeOut,
  );
}

/// The first refusing field in reading order, or null.
///
/// Pre-order, because the forms are a `Column` inside a scroll view — mounted
/// top to bottom deliberately, so every field is in the tree whether or not it
/// is on screen, and the traversal still stops at the first one that refused.
BuildContext? _firstRefusedField(BuildContext root) {
  BuildContext? found;
  void visit(Element element) {
    if (found != null) return;
    final state = element is StatefulElement ? element.state : null;
    if (state is FormFieldState) {
      if (state.hasError) {
        found = element;
        return;
      }
    }
    element.visitChildren(visit);
  }

  root.visitChildElements(visit);
  return found;
}

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

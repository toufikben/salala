import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/app.dart';
import 'package:salala/core/utils/triage.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/buyer.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/placement.dart';
import 'package:salala/data/models/symptom.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/vet_visit.dart';
import 'package:salala/data/models/weight_entry.dart';
import 'package:salala/presentation/providers/app_providers.dart';
import 'package:salala/presentation/providers/triage_providers.dart';
import 'package:salala/presentation/widgets/date_tile.dart';
import 'package:salala/services/app_lock_service.dart';
import 'package:salala/services/reminder_scheduler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'fake_notification_writer.dart';
import 'fake_pack_files.dart';
import 'fake_secure_storage.dart';
import 'test_db.dart';

/// Seeds the PIN flag the way `main()` does after reading the keystore.
class SeededHasPin extends HasPin {
  SeededHasPin(this._value);

  final bool _value;

  @override
  bool build() => _value;
}

/// A launch that already rebuilt its alarms, so `claim()` refuses the screen.
class AlreadyResynced extends RemindersResynced {
  @override
  bool build() => true;
}

/// Pumps long enough for background-isolate database work to land.
///
/// sqflite runs on another isolate, which the fake-async zone of `testWidgets`
/// cannot advance: awaiting such a future directly hangs the test forever
/// without even tripping its own timeout. So every round pumps the fake clock
/// once and then hands real time to `runAsync` for the isolate to answer in.
///
/// The rounds are not cut short when the loading spinner disappears — a save
/// finishes and pops a route without ever showing a spinner, so the real wait
/// has to continue regardless. Ten rounds are a floor, and after them the wait
/// is keyed on the bar instead of on a count: while an indeterminate bar is on
/// screen the page is demonstrably not finished, and when the bound runs out
/// that is stated outright. The bound is what made run `37431948933` say "a
/// database-backed widget never finished loading" twenty times, which is a
/// section that *never* resolves — the ten-round theory this replaced had
/// guessed a slow one, and was wrong.
Future<void> settleRealIo(WidgetTester tester) async {
  for (var round = 0; round < 10; round++) {
    await tester.pump(const Duration(milliseconds: 25));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
  }

  // Anything indeterminate is still spinning, which `pumpAndSettle` reads as a
  // page that never settles: the timeout it throws names the animation, not the
  // section that never resolved. So this waits for the bar itself, and asks for
  // the `ProgressIndicator` *subtype* because `find.byType` compares runtime
  // types exactly and would match neither of the concrete bars (finders.dart
  // :1642). A section that loads with a linear bar used to slip past the guard
  // below and fail 19 screens later as `pumpAndSettle timed out` (run
  // 37383228340). The bound stays finite so a genuinely stuck widget still
  // fails loudly rather than hanging the suite.
  for (
    var round = 0;
    round < 40 && tester.any(find.bySubtype<ProgressIndicator>());
    round++
  ) {
    await tester.pump(const Duration(milliseconds: 25));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
  }

  if (tester.any(find.bySubtype<ProgressIndicator>())) {
    // Named by widget type, because the app has two bars and they mean
    // different things: a linear one is the triage section, a circular one is a
    // whole page or a form still waiting on its first query.
    final stuck = tester
        .widgetList(find.bySubtype<ProgressIndicator>())
        .map((bar) => bar.runtimeType.toString())
        .toSet()
        .join(', ');
    throw StateError(
      'a database-backed widget never finished loading ($stuck)',
    );
  }

  // Finite pumping, not `pumpAndSettle`: route transitions are animations, and
  // this helper is also used right after a write pops a route.
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Waits until the scheduler has been handed a whole save or a whole launch.
///
/// The dose is written on another isolate, so the alarms reach the writer some
/// real milliseconds after the tap or the first frame that asked for them.
/// Asserting straight after either raced that: run 37353640524 read zero alarms
/// from a dose that had them, while the identical code had been green twice.
///
/// [calls] is the writer's own count — the two clears a replace always makes,
/// plus one write per alarm — so a save that reached the scheduler and booked
/// nothing still fails here, naming how far the log got, instead of quietly
/// satisfying an `isEmpty` check either way.
Future<void> waitForSchedulerCalls(
  WidgetTester tester,
  FakeNotificationWriter notifications,
  int calls,
) async {
  for (var round = 0; round < 40 && notifications.log.length < calls; round++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
  }
  if (notifications.log.length < calls) {
    throw StateError(
      'the scheduler reached ${notifications.log.length} of $calls calls '
      '(${notifications.log.join(', ')}), and wrote '
      '${notifications.written.length} alarm(s)',
    );
  }
  await settleRealIo(tester);
}

/// Boots the real router + theme + localizations against a temporary database
/// and a fake keystore. [seed] rows are inserted through the real DAO before
/// the first frame, so the UI is exercised against genuine SQL results.
Future<FakeSecureStorage> pumpSalala(
  WidgetTester tester, {
  Locale? locale,
  bool hasPin = false,
  FakeNotificationWriter? notifications,
  // The share sheet and the file picker, which no test runner can answer.
  FakePackFiles? packFiles,
  // Whether opening the app rebuilds the alarms from the ledger, which is what
  // a real launch does. Off by default: a test about saving one dose should not
  // also be handed the alarms that opening the list booked for it. The launch
  // path switches this on and tests itself.
  bool resyncOnLaunch = false,
  List<Animal> seed = const <Animal>[],
  List<Vaccination> seedVaccinations = const <Vaccination>[],
  List<WeightEntry> seedWeights = const <WeightEntry>[],
  List<HealthTest> seedHealthTests = const <HealthTest>[],
  List<VetVisit> seedVisits = const <VetVisit>[],
  List<Symptom> seedSymptoms = const <Symptom>[],
  List<Buyer> seedBuyers = const <Buyer>[],
  List<Placement> seedPlacements = const <Placement>[],
  // A database the test wants bent before the first frame, after the seeds have
  // landed. The write path is otherwise the shipped one, so the only way to hand
  // a screen a genuine `the database said no` is to make SQLite say it: a test
  // that wants to prove a form survives a refused insert installs a trigger here
  // rather than faking a dao.
  Future<void> Function(Database db)? beforeLaunch,
}) async {
  final storage = FakeSecureStorage();
  late Database database;

  // The triage table, read here instead of from inside its provider, and read
  // the way `test/core/triage_test.dart` reads it: synchronously, off disk.
  // Three measured facts rule out the app's own `rootBundle` call here. It
  // completes from a test body; it never completes from a provider body (run
  // 37435525579 left 21 screens holding a linear bar); and it never completes
  // inside `tester.runAsync` either, which run 37437885813 proved the hard way
  // — that attempt hung ten minutes and then denied every later `runAsync` in
  // the file, since a pending one blocks the next. Nothing about the contents is
  // faked: this is the shipped file, parsed by the shipped parser, and the
  // provider's own read path has no harness coverage because the fake-async zone
  // cannot host it. Real Flutter has no such zone, and the phone is its judge.
  final rulesSource = File(triageRulesAsset).readAsStringSync();

  // `main()` does this for the real app; without it a non-English DateFormat
  // throws on the first date a widget test asks a reminder to render.
  await initializeDateFormatting();

  // The scheduling rules are the app's own code, so widget tests run them for
  // real and only the writer below stands in for the phone. `timezone` refuses
  // to convert any instant until its tables are loaded, which `bootstrap()` does
  // in the app and cannot do here because the timezone lookup is a channel call.
  // UTC because the runner's own clock is UTC: pinning another zone would make
  // the wall-clock times below drift with the machine the tests ran on.
  tz_data.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('UTC'));

  // The provider refuses a default instance on purpose: an unbootstrapped plugin
  // throws on the first schedule call. Every test therefore gets the real
  // scheduler over a writer that records instead of delivering, and one that
  // cares about the alarms passes its own writer and reads it back.
  final writer = notifications ?? FakeNotificationWriter();
  final scheduler = ReminderScheduler(writer);

  await tester.runAsync(() async {
    database = await openTestDatabase();
    final daos = Daos(database);
    var nowMs = 1;
    for (final animal in seed) {
      await daos.animals.create(animal, nowMs: nowMs++);
    }
    // Records are inserted after the animals because `animal_id` is a foreign
    // key: a dose for an animal that is not there yet would be rejected.
    for (final dose in seedVaccinations) {
      await daos.vaccinations.create(dose, nowMs: nowMs++);
    }
    for (final entry in seedWeights) {
      await daos.weights.create(entry, nowMs: nowMs++);
    }
    for (final record in seedHealthTests) {
      await daos.healthTests.create(record, nowMs: nowMs++);
    }
    for (final visit in seedVisits) {
      await daos.vetVisits.create(visit, nowMs: nowMs++);
    }
    for (final symptom in seedSymptoms) {
      await daos.symptoms.create(symptom, nowMs: nowMs++);
    }
    // A buyer before a placement for the same reason: `placements.buyer_id` is a
    // foreign key, so the contact a seeded handover names has to exist first.
    for (final buyer in seedBuyers) {
      await daos.buyers.create(buyer, nowMs: nowMs++);
    }
    for (final placement in seedPlacements) {
      await daos.placements.create(placement, nowMs: nowMs++);
    }
    if (beforeLaunch != null) await beforeLaunch(database);
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        triageRulesProvider.overrideWith(
          (ref) async => parseRules(rulesSource),
        ),
        appLockProvider.overrideWithValue(AppLockService(storage: storage)),
        hasPinProvider.overrideWith(() => SeededHasPin(hasPin)),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        if (packFiles != null) packFilesProvider.overrideWithValue(packFiles),
        if (!resyncOnLaunch)
          remindersResyncProvider.overrideWith(AlreadyResynced.new),
        if (locale != null) initialLocaleProvider.overrideWithValue(locale),
      ],
      child: const SalalaApp(),
    ),
  );
  await settleRealIo(tester);
  return storage;
}

/// A `beforeLaunch` hook that makes every insert into [table] fail the way a
/// real database fails it, so a write path is exercised against a genuine
/// refusal instead of a faked dao (D6). Installed after the seeds, which still
/// land; reads stay honest, so the screen around the form behaves normally.
Future<void> Function(Database) refuseWritesTo(String table) => (db) async {
  await db.execute(
    'CREATE TRIGGER refuse_insert_$table BEFORE INSERT ON $table '
    "BEGIN SELECT RAISE(ABORT, 'the ledger is full'); END",
  );
};

/// A `beforeLaunch` hook that makes every delete from [table] fail, for the
/// screens that have to hold a record they could not remove. Same seam as
/// [refuseWritesTo] and the same reason: a real SQLite refusal, not a fake dao.
Future<void> Function(Database) refuseDeletesOf(String table) => (db) async {
  await db.execute(
    'CREATE TRIGGER refuse_delete_$table BEFORE DELETE ON $table '
    "BEGIN SELECT RAISE(ABORT, 'the ledger is full'); END",
  );
};

/// A `beforeLaunch` hook that makes every update of [table] fail, for the screens
/// that reopen a row already in the ledger. [refuseWritesTo] only fires on an
/// insert, so an edit path that goes through `db.update` would sail past it and
/// a test would pass on a write that never got refused.
Future<void> Function(Database) refuseUpdatesOf(String table) => (db) async {
  await db.execute(
    'CREATE TRIGGER refuse_update_$table BEFORE UPDATE ON $table '
    "BEGIN SELECT RAISE(ABORT, 'the ledger is full'); END",
  );
};

/// Taps a form's Save and waits for SQLite to answer, without the full launch
/// settle: the refusal these tests want arrives late, and `settleRealIo`'s
/// pumping outlives the snackbar it has to be read from.
///
/// [dialogTitle] scopes the button to one alert, because a handover form can
/// have a contact form open on top of it and both end in a Save button.
///
/// [waitingFor] is the sentence the caller is about to assert. It defaults to the
/// database's refusal because that is what most of these tests are waiting for; a
/// form that refuses a date itself has to say so, or the wait settles on whatever
/// appeared and the assertion below it reads a sentence from the phase before.
Future<void> tapSaveAndGetAnswer(
  WidgetTester tester, {
  String? dialogTitle,
  String waitingFor = saveRefusalSentence,
}) async {
  final save = dialogTitle == null
      ? find.widgetWithText(FilledButton, 'Save')
      : find.descendant(
          of: find.widgetWithText(AlertDialog, dialogTitle),
          matching: find.widgetWithText(FilledButton, 'Save'),
        );
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await settleRefusal(tester, waitingFor: waitingFor);
}

/// The whole evidence that a refused write stayed the screen's: the sentence, the
/// screen still open with the typed word in its field, and a Save button that
/// answers a tap again. [stillOnScreen] is that screen's own type rather than a
/// caption, because half these forms are titled with the same words as the button
/// that opened them. [label] is the field [text] was typed into, and
/// [notifications] the writer that must not have been handed an alarm for a row
/// that was never written.
void expectRefusedWrite(
  WidgetTester tester, {
  required Finder stillOnScreen,
  required String label,
  required String text,
  String? dialogTitle,
  FakeNotificationWriter? notifications,
}) {
  expect(
    find.text(saveRefusalSentence),
    findsOneWidget,
    reason: 'a refused write has to say so, not sit on a spinner',
  );
  expect(stillOnScreen, findsOneWidget);
  expect(
    tester
        .widget<FilledButton>(
          dialogTitle == null
              ? find.widgetWithText(FilledButton, 'Save')
              : find.descendant(
                  of: find.widgetWithText(AlertDialog, dialogTitle),
                  matching: find.widgetWithText(FilledButton, 'Save'),
                ),
        )
        .onPressed,
    isNotNull,
  );
  expect(
    tester
        .widget<TextFormField>(
          dialogTitle == null
              ? find.widgetWithText(TextFormField, label)
              : find.descendant(
                  of: find.widgetWithText(AlertDialog, dialogTitle),
                  matching: find.widgetWithText(TextFormField, label),
                ),
        )
        .controller!
        .text,
    text,
  );
  if (notifications != null) {
    expect(notifications.log, isEmpty);
  }
}

/// The sentence a refused write is answered with, as one token.
///
/// A test that waits for a refusal and a test that asserts one have to name the
/// same string, and a sentence copy-pasted into both is how they drift apart: the
/// wait settles on whatever appeared and the assertion reads a different one. The
/// same argument holds for every refusal sentence below.
const String saveRefusalSentence =
    'This could not be saved. Nothing was written.';
const String deleteRefusalSentence =
    'This could not be deleted. The record is still there.';
const String beforeBirthSentence = 'This date is before this animal was born.';
const String whelpingBeforeMatingSentence =
    'The whelping date is before the mating date.';
const String weaningBeforeWhelpingSentence =
    'The weaning date is before the whelping date.';
const String doseDueBeforeDoseSentence =
    'The next dose is due before this dose was given.';
const String certificateBeforeTestSentence =
    'This certificate expires before the day of the test it certifies.';
const String appLockRefusalSentence =
    'The phone would not change the app lock.';
const String languageRefusalSentence =
    'The phone would not keep this language.';

/// The wait a refusal has to be read from: as long as SQLite takes to answer, and
/// no longer — the snackbar it answered with dismisses four seconds after it
/// appears, on the fake clock this helper does not run forward.
///
/// It polls for [waitingFor] rather than for *any* snackbar, because those are two
/// different facts and only one of them is the test's. `ScaffoldMessenger` shows
/// one snackbar at a time and queues the next, so a form refused twice keeps
/// displaying the *first* reason while the second is still waiting; a helper that
/// answers as soon as anything appears lets the second phase assert the first
/// phase's sentence. CI measured that instead of leaving it to be reasoned about:
/// the six birth-date tests all passed their first half, SQLite refused their
/// second half as the log shows, and every one of them failed on a sentence that
/// had not been displayed yet.
///
/// So a different sentence on screen costs the four seconds the app was going to
/// spend on it, and the poll continues. Nothing on screen waits out the write the
/// way the old fixed 60 ms sleep never could: on a loaded CI machine a refusal that
/// arrives late looks exactly like a refusal that never happened.
///
/// If [waitingFor] never arrives the loop gives up and the assertion the caller was
/// about to make fails on its own words, which is the right outcome — a wait that
/// timed out *is* a refusal that did not arrive.
Future<void> settleRefusal(
  WidgetTester tester, {
  required String waitingFor,
}) async {
  final sentence = find.descendant(
    of: find.byType(SnackBar),
    matching: find.text(waitingFor),
  );
  for (var round = 0; round < 40; round++) {
    await tester.pump();
    if (sentence.evaluate().isNotEmpty) {
      // One frame of the entry animation, so the sentence is where it will be
      // when a test reads it back, not half-slid in from the bottom.
      await tester.pump(const Duration(milliseconds: 120));
      return;
    }
    if (find.byType(SnackBar).evaluate().isNotEmpty) {
      // Another refusal is on screen and this test's sentence is queued behind
      // it: spend the display time the shipped app would have spent.
      await tester.pump(const Duration(seconds: 4));
      continue;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 25)),
    );
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

/// A date typed into the picker rather than tapped on its calendar.
///
/// Any test that cares what a form does with a date has to go through this
/// dialog: the calendar's cells are numbered by whatever month the run falls in,
/// so tapping a day cannot express "the third of January" on a machine whose
/// today is unknown. The dialog's input mode can. It parses `mm/dd/yyyy`,
/// because `MaterialLocalizations.parseCompactDate`
/// (material_localizations.dart:904) splits the text on `/` with that order
/// written down as an assumption, and a widget test's locale is `en_US`, where
/// the help text above the field says the same thing. Both halves of that pair
/// matter — the app's Arabic and French builds show a different order than the
/// parser accepts, which is the phone's to check and not this runner's.
///
/// [scope] is the screen or dialog that owns the tile. A form with three dates
/// needs the tile's index; a test that leaves the scope out finds whichever
/// `DateTile` the widget tree happens to expose first, which is not the one it
/// means to set.
Future<void> typeDateIntoPicker(
  WidgetTester tester, {
  required Type scope,
  required int tile,
  required String usDay,
}) async {
  final field = find
      .descendant(of: find.byType(scope), matching: find.byType(DateTile))
      .at(tile);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byIcon(Icons.edit_outlined),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.byType(TextFormField),
    ),
    usDay,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byType(DatePickerDialog),
      matching: find.widgetWithText(TextButton, 'OK'),
    ),
  );
  await tester.pumpAndSettle();
}

/// The same day in the order the picker's input mode parses.
///
/// Written from a timestamp instead of typed as a literal, so a test that means
/// "sixteen months before the run's today" stays true on a runner in 2031.
String usDay(int ms) {
  final day = DateTime.fromMillisecondsSinceEpoch(ms);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(day.month)}/${two(day.day)}/${day.year}';
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/app.dart';
import 'package:salala/core/utils/triage.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/vet_visit.dart';
import 'package:salala/data/models/weight_entry.dart';
import 'package:salala/presentation/providers/app_providers.dart';
import 'package:salala/presentation/providers/triage_providers.dart';
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

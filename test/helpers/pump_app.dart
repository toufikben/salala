import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:salala/app.dart';
import 'package:salala/data/db/daos.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/health_test.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/data/models/vet_visit.dart';
import 'package:salala/data/models/weight_entry.dart';
import 'package:salala/presentation/providers/app_providers.dart';
import 'package:salala/services/app_lock_service.dart';
import 'package:salala/services/reminder_scheduler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'fake_notification_writer.dart';
import 'fake_secure_storage.dart';
import 'test_db.dart';

/// Seeds the PIN flag the way `main()` does after reading the keystore.
class SeededHasPin extends HasPin {
  SeededHasPin(this._value);

  final bool _value;

  @override
  bool build() => _value;
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
/// has to continue regardless. A spinner still on screen afterwards means the
/// widget really is stuck, and that fails loudly instead of hanging.
Future<void> settleRealIo(WidgetTester tester) async {
  for (var round = 0; round < 10; round++) {
    await tester.pump(const Duration(milliseconds: 25));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 15)),
    );
  }

  if (tester.any(find.byType(CircularProgressIndicator))) {
    throw StateError('a database-backed widget never finished loading');
  }

  // Finite pumping, not `pumpAndSettle`: route transitions are animations, and
  // this helper is also used right after a write pops a route.
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Boots the real router + theme + localizations against a temporary database
/// and a fake keystore. [seed] rows are inserted through the real DAO before
/// the first frame, so the UI is exercised against genuine SQL results.
Future<FakeSecureStorage> pumpSalala(
  WidgetTester tester, {
  Locale? locale,
  bool hasPin = false,
  FakeNotificationWriter? notifications,
  List<Animal> seed = const <Animal>[],
  List<Vaccination> seedVaccinations = const <Vaccination>[],
  List<WeightEntry> seedWeights = const <WeightEntry>[],
  List<HealthTest> seedHealthTests = const <HealthTest>[],
  List<VetVisit> seedVisits = const <VetVisit>[],
}) async {
  final storage = FakeSecureStorage();
  late Database database;

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
        appLockProvider.overrideWithValue(AppLockService(storage: storage)),
        hasPinProvider.overrideWith(() => SeededHasPin(hasPin)),
        reminderSchedulerProvider.overrideWithValue(scheduler),
        if (locale != null) initialLocaleProvider.overrideWithValue(locale),
      ],
      child: const SalalaApp(),
    ),
  );
  await settleRealIo(tester);
  return storage;
}

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/db/settings_dao.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/startup_failure_screen.dart';
import 'services/app_lock_service.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _launch();
  } catch (error, stack) {
    // The launch reads the database before the first frame, so a phone that
    // will not open it has no screen to fail into. One frame with the sentence
    // is the difference between a dead icon and a breeder who knows the records
    // are still there; the log carries what a remote diagnosis would need.
    debugPrint('Startup failed: $error\n$stack');
    runApp(const StartupFailureScreen());
  }
}

Future<void> _launch() async {
  // DateFormat needs the non-English symbol tables registered up front.
  await initializeDateFormatting();
  // D21: one numeral system on screen. The Material date picker renders its
  // header and month label through `intl` rather than through `formatDayFor`,
  // and on the phone it painted `٦ أكتوبر ٢٠٢٦` beside a tile reading
  // `6 أكتوبر 2026`. This is `intl`'s own switch for that; the picker is the
  // surface it exists for.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);

  final db = await AppDatabase.openAt(
    p.join(await getDatabasesPath(), 'salala.db'),
  );

  final languageCode = await SettingsDao(db).read(SettingKeys.languageCode);
  final hasPin = await AppLockService().isLocked();

  // Bootstrapped before the first frame so the permission prompt and the
  // timezone pin are both settled by the time a dose can be saved. The single
  // instance is handed to the tree: a second, unbootstrapped scheduler would
  // throw on its first schedule call.
  final reminders = ReminderScheduler(PluginNotifications());
  try {
    await reminders.bootstrap();
  } catch (error) {
    // A phone that refuses notifications must still open the ledger. The
    // reminders are the loss, and Settings shows nothing about them, so the
    // failure has to leave a trace for whoever debugs a missing alarm.
    debugPrint('Reminder bootstrap failed: $error');
  }

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      reminderSchedulerProvider.overrideWithValue(reminders),
      initialLocaleProvider.overrideWithValue(
        languageCode == null || languageCode == 'system'
            ? null
            : Locale(languageCode),
      ),
    ],
  );
  container.read(hasPinProvider.notifier).set(hasPin);

  runApp(
    UncontrolledProviderScope(container: container, child: const SalalaApp()),
  );
}

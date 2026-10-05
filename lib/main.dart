import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'data/db/app_database.dart';
import 'data/db/settings_dao.dart';
import 'presentation/providers/app_providers.dart';
import 'services/app_lock_service.dart';
import 'services/reminder_scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // DateFormat needs the non-English symbol tables registered up front.
  await initializeDateFormatting();

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

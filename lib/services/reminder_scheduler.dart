import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/l10n/app_localizations.dart';
import '../core/utils/reminders.dart';

/// The narrow piece of the notification system the app actually uses.
///
/// The app owns this seam because the plugin's own constructor is a factory, so
/// it cannot be subclassed: without it, which alarms get written, in what order,
/// and in which wording would be the one piece of logic no test could reach.
abstract class NotificationWriter {
  /// Creates the channel and asks for the permission Android 13+ needs before
  /// anything can be shown.
  Future<void> initialise();

  Future<void> write({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required AndroidScheduleMode mode,
  });

  Future<void> clear(int id);
}

/// [NotificationWriter] over `flutter_local_notifications`, the only place in
/// the app allowed to name that package.
class PluginNotifications implements NotificationWriter {
  PluginNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const AndroidNotificationDetails _channel = AndroidNotificationDetails(
    'salala_reminders',
    'Reminders',
    channelDescription:
        'Doses and screenings coming up, so a booking can be made in time.',
    importance: Importance.high,
    priority: Priority.high,
  );

  @override
  Future<void> initialise() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> write({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required AndroidScheduleMode mode,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: mode,
    );
  }

  @override
  Future<void> clear(int id) => _plugin.cancel(id: id);
}

/// Turns a record's due date into whatever alarms the operating system should be
/// holding for it.
///
/// Reminders are written to the phone, not tracked by the app: they survive a
/// force-stop and a reboot (the manifest declares the plugin's boot receiver for
/// that), and deleting the record takes them back out.
class ReminderScheduler {
  ReminderScheduler(this._writer);

  final NotificationWriter _writer;

  /// Pins the phone's own timezone before anything is scheduled. Without it the
  /// timezone package sits on UTC and a nine-in-the-morning reminder would wake
  /// a breeder at midnight local time.
  Future<void> bootstrap() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _writer.initialise();
  }

  /// Replaces everything scheduled for one record with what its due date now
  /// implies. Cancelling first is what makes an edit idempotent: a dose moved a
  /// week later must not leave the old alarm behind.
  Future<void> replace({
    required String recordId,
    required int? dueMs,
    required AppLocalizations l10n,
    required String title,
    required String what,
    required String dueDay,
  }) async {
    await cancel(recordId);
    for (final reminder in remindersFor(recordId: recordId, dueMs: dueMs)) {
      await _writer.write(
        id: reminder.notificationId,
        title: title,
        body: _body(reminder, l10n: l10n, what: what, dueDay: dueDay),
        at: tz.TZDateTime.from(reminder.at, tz.local),
        // Inexact on purpose: an exact alarm needs SCHEDULE_EXACT_ALARM, which
        // Google Play audits, for a message whose only deadline is "that
        // morning". Allow-while-idle so a phone asleep in a pocket still gets it.
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancel(String recordId) async {
    for (final kind in ReminderKind.values) {
      await _writer.clear(notificationIdFor(recordId, kind));
    }
  }

  String _body(
    Reminder reminder, {
    required AppLocalizations l10n,
    required String what,
    required String dueDay,
  }) {
    return switch (reminder.kind) {
      ReminderKind.headsUp => l10n.reminderHeadsUpBody(what, dueDay),
      ReminderKind.dueToday => l10n.reminderDueBody(what),
    };
  }
}

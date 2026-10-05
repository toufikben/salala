import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/l10n/app_localizations.dart';
import '../core/utils/reminders.dart';

/// The only file in the app that talks to the notification plugin.
///
/// Reminders are written to the operating system, not tracked by the app: they
/// survive a force-stop and a reboot (the manifest declares the plugin's boot
/// receiver for that), and deleting the record cancels them again.
class ReminderScheduler {
  ReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
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

  /// Opens the channel, pins the phone's own timezone, and asks the permission
  /// Android 13+ requires before anything can be shown.
  ///
  /// Without `setLocalLocation` the timezone package defaults to UTC, and a
  /// nine-in-the-morning reminder would wake a breeder at midnight.
  Future<void> bootstrap() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
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
      await _plugin.zonedSchedule(
        id: reminder.notificationId,
        title: title,
        body: _body(reminder, l10n: l10n, what: what, dueDay: dueDay),
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.local),
        notificationDetails: const NotificationDetails(android: _channel),
        // Inexact on purpose: an exact alarm needs SCHEDULE_EXACT_ALARM, which
        // Google Play audits and which a breeder has no reason to grant for a
        // message whose only deadline is "that morning".
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancel(String recordId) async {
    for (final kind in ReminderKind.values) {
      await _plugin.cancel(id: notificationIdFor(recordId, kind));
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

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
  ///
  /// Returns the payload of the notification that *launched* the app, if one
  /// did: a breeder who taps a dose alert on a cold phone expects the dog, not
  /// the herd. The live taps arrive through [onTap] instead, because by then
  /// there is a running app to send them into.
  Future<String?> initialise({void Function(String? payload)? onTap});

  Future<void> write({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required AndroidScheduleMode mode,
    String? payload,
  });

  Future<void> clear(int id);

  /// Takes every notification this app has booked out of the phone.
  Future<void> clearAll();
}

/// [NotificationWriter] over `flutter_local_notifications`, the only place in
/// the app allowed to name that package.
class PluginNotifications implements NotificationWriter {
  PluginNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// The small icon, and the reason it is not the launcher icon: Android draws
  /// a notification's small icon as a flat silhouette and throws away every
  /// colour in it, so handing it `ic_launcher` produced a white square on a
  /// white circle. This one is drawn as a silhouette to begin with.
  static const String smallIcon = 'ic_notification';

  static const AndroidNotificationDetails _channel = AndroidNotificationDetails(
    'salala_reminders',
    'Reminders',
    channelDescription:
        'Doses and screenings coming up, so a booking can be made in time.',
    importance: Importance.high,
    priority: Priority.high,
    icon: smallIcon,
  );

  @override
  Future<String?> initialise({void Function(String? payload)? onTap}) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@drawable/$smallIcon'),
        // Declared even though iOS is not shipped yet: without it the plugin
        // throws on a non-Android target instead of doing nothing, and the day
        // the app is built for iOS this line is already the right one.
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: onTap == null
          ? null
          : (response) => onTap(response.payload),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch == null || !launch.didNotificationLaunchApp) return null;
    return launch.notificationResponse?.payload;
  }

  @override
  Future<void> write({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime at,
    required AndroidScheduleMode mode,
    String? payload,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: at,
      notificationDetails: const NotificationDetails(android: _channel),
      androidScheduleMode: mode,
      payload: payload,
    );
  }

  @override
  Future<void> clear(int id) => _plugin.cancel(id: id);

  @override
  Future<void> clearAll() => _plugin.cancelAll();
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
  ///
  /// Returns the payload of the alert that launched the app, if one did — the
  /// caller decides where a tap lands, and on a cold start it has to wait for a
  /// router that does not exist yet.
  Future<String?> bootstrap({void Function(String? payload)? onTap}) async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    return _writer.initialise(onTap: onTap);
  }

  /// Replaces everything scheduled for one record with what its due date now
  /// implies. Cancelling first is what makes an edit idempotent: a dose moved a
  /// week later must not leave the old alarm behind.
  ///
  /// [animalId] rides along as the notification's payload, and it is the whole of
  /// the tap: a reminder says "Rabies is due" and the breeder who taps it wants
  /// that dog, not a list to search through. Read at tap time, so an animal
  /// deleted in the meantime lands on the ledger's own "this animal is gone".
  Future<void> replace({
    required String recordId,
    required String animalId,
    required int? dueMs,
    required AppLocalizations l10n,
    required String title,
    required String what,
    required String dueDay,
    // The caller's clock, not the machine's: `reconcile` decides what is booked
    // against one `now`, and if the write re-filtered against a different one a
    // pinned-clock caller would book a record and then write none of its alarms.
    DateTime? now,
  }) async {
    await cancel(recordId);
    for (final reminder in remindersFor(
      recordId: recordId,
      dueMs: dueMs,
      now: now,
    )) {
      await _writer.write(
        id: reminder.notificationId,
        title: title,
        body: _body(reminder, l10n: l10n, what: what, dueDay: dueDay),
        // The wall-clock fields, not the instant: `remindersFor` worked out
        // "nine in the morning" as a day and a time, so the alarm has to be
        // nine in the morning *where the phone is*. `TZDateTime.from` would
        // read the value as an instant and re-express it in the phone's zone,
        // which is only the same answer when the two zones are one.
        at: _wallClock(reminder.at),
        // Inexact on purpose: an exact alarm needs SCHEDULE_EXACT_ALARM, which
        // Google Play audits, for a message whose only deadline is "that
        // morning". Allow-while-idle so a phone asleep in a pocket still gets it.
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: animalId,
      );
    }
  }

  Future<void> cancel(String recordId) async {
    for (final kind in ReminderKind.values) {
      await _writer.clear(notificationIdFor(recordId, kind));
    }
  }

  /// Takes every alarm this app holds out of the phone, for the moments when
  /// records do not change but *vanish*.
  ///
  /// [cancel] works off a record id, which is enough when one row is edited or
  /// deleted: the screen still holds the id. It is not enough when the rows the
  /// alarms were booked from are gone as a group — an animal deleted with its
  /// ledger under it, or a restore that replaced the whole herd — because
  /// nothing in the database names those alarms any more, and a message at nine
  /// in the morning about a dose of an animal that no longer exists is noise a
  /// breeder cannot act on. So the wholesale paths empty the phone and let the
  /// rebuild that follows re-book exactly what is left.
  Future<void> clearEverything() => _writer.clearAll();

  /// [at]'s calendar fields read as a wall clock in the phone's zone.
  static tz.TZDateTime _wallClock(DateTime at) =>
      tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour, at.minute);

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

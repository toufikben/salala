import 'package:salala/core/l10n/app_localizations.dart';
import 'package:salala/services/reminder_scheduler.dart';

/// One `replace` exactly as the user interface asked for it.
class ReminderRequest {
  const ReminderRequest({
    required this.recordId,
    required this.dueMs,
    required this.title,
    required this.what,
    required this.dueDay,
  });

  final String recordId;
  final int? dueMs;

  /// Which animal the notification will be titled with.
  final String title;

  /// The dose or screening name as the breeder typed it.
  final String what;

  /// The due date already rendered in the language on screen.
  final String dueDay;
}

/// Stands in for the notification plugin in tests.
///
/// The real scheduler needs a platform channel and a timezone database, so a
/// widget test could only ever crash here. What a test should be checking is
/// which record the interface handed over, with which due date and which
/// localized copy — so that is precisely what this records. The scheduling
/// arithmetic it would have run is covered directly in
/// `test/core/reminders_test.dart`.
class FakeReminderScheduler extends ReminderScheduler {
  FakeReminderScheduler() : super();

  final List<ReminderRequest> replacements = <ReminderRequest>[];
  final List<String> cancellations = <String>[];

  @override
  Future<void> bootstrap() async {}

  @override
  Future<void> replace({
    required String recordId,
    required int? dueMs,
    required AppLocalizations l10n,
    required String title,
    required String what,
    required String dueDay,
  }) async {
    replacements.add(
      ReminderRequest(
        recordId: recordId,
        dueMs: dueMs,
        title: title,
        what: what,
        dueDay: dueDay,
      ),
    );
  }

  @override
  Future<void> cancel(String recordId) async {
    cancellations.add(recordId);
  }
}

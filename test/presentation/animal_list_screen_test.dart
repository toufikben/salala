import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/core/utils/reminders.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/data/models/vaccination.dart';
import 'package:salala/presentation/screens/animal_form_screen.dart';

import '../helpers/fake_notification_writer.dart';
import '../helpers/pump_app.dart';

Animal _draft({String name = 'Atlas', bool breeding = false}) => Animal(
  id: '',
  name: name,
  species: 'dog',
  sex: Sex.male,
  status: AnimalStatus.active,
  isBreedingStock: breeding,
  createdAt: 0,
  updatedAt: 0,
);

void main() {
  // A tap that misses its widget must fail the test instead of only warning;
  // a missed tap here once produced a green test that had saved nothing.
  WidgetController.hitTestWarningShouldBeFatal = true;

  testWidgets('empty herd shows the guided empty state', (tester) async {
    await pumpSalala(tester);

    expect(find.text('No animals yet'), findsOneWidget);
    // Exactly one way in: the device check found a FAB stacked on top of the
    // empty state's own button, and the two competed for the same thumb.
    expect(find.text('Add animal'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('animals are grouped, breeding stock first', (tester) async {
    await pumpSalala(
      tester,
      seed: <Animal>[
        _draft(name: 'Bella'),
        _draft(name: 'Zeus', breeding: true),
      ],
    );

    expect(find.text('Breeding stock'), findsOneWidget);
    expect(find.text('Zeus'), findsOneWidget);
    expect(find.text('All animals'), findsOneWidget);

    // With a herd to work on, the corner button is back.
    expect(find.byType(FloatingActionButton), findsOneWidget);

    final breedingIndex = tester.getTopLeft(find.text('Breeding stock')).dy;
    final allIndex = tester.getTopLeft(find.text('All animals')).dy;
    expect(breedingIndex, lessThan(allIndex));
  });

  testWidgets('the form refuses a nameless animal and saves a valid one', (
    tester,
  ) async {
    // A phone-sized surface: the default 800x600 test window is shorter than
    // the form, and the Save button has to be reachable by a real hit test.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpSalala(tester);

    // The herd is empty here, so the only affordance is the empty state's own
    // button — the FAB is deliberately absent until there is something to add to.
    await tester.tap(find.widgetWithText(FilledButton, 'Add animal'));
    await tester.pumpAndSettle();

    final save = find.widgetWithText(FilledButton, 'Save');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('A name is required'), findsOneWidget);
    expect(find.byType(AnimalFormScreen), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Nala');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Species'),
      'dog',
    );
    // Focusing a field can scroll the button out from under the tap, so the
    // scroll is re-asserted rather than assumed.
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    // The write goes to the database, so the fake clock alone cannot finish it.
    await settleRealIo(tester);

    // The route has to be gone: while the form is still open its own name field
    // also contains "Nala", and asserting on the text alone would pass on a
    // tap that never landed.
    expect(find.byType(AnimalFormScreen), findsNothing);
    expect(find.text('All animals'), findsOneWidget);
    expect(find.text('Nala'), findsOneWidget);
  });

  testWidgets('a locked app opens on the PIN gate, not the herd', (
    tester,
  ) async {
    await pumpSalala(tester, hasPin: true);

    expect(find.text('Salala is locked'), findsOneWidget);
    expect(find.text('Animals'), findsNothing);
  });

  testWidgets('Arabic renders right-to-left', (tester) async {
    await pumpSalala(tester, locale: const Locale('ar'));

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('الحيوانات'),
      ),
      findsOneWidget,
    ); // the nav bar repeats the label, so scope the check to the title
    final context = tester.element(find.byType(AppBar).first);
    expect(Directionality.of(context), TextDirection.rtl);
  });

  group('the launch that rebuilds the alarms', () {
    // Android drops an app's pending alarms when it is force-stopped or cleared
    // from recents — measured on the test phone, where `am force-stop` took
    // every booked reminder out and left the ledger rows untouched. Opening the
    // app is therefore the recovery, and these two tests are it: one dose due
    // in twenty days, and an alarm that reappears without anyone saving.
    const String nalaId = 'animal-nala';

    Animal nala() => Animal(
      id: nalaId,
      name: 'Nala',
      species: 'dog',
      sex: Sex.female,
      status: AnimalStatus.active,
      createdAt: 0,
      updatedAt: 0,
    );

    Vaccination doseDueInDays(int days) => Vaccination(
      id: '',
      animalId: nalaId,
      vaccineName: 'Rabies',
      dateAdministered: DateTime.now()
          .subtract(const Duration(days: 10))
          .millisecondsSinceEpoch,
      nextDueDate: DateTime.now()
          .add(Duration(days: days))
          .millisecondsSinceEpoch,
      createdAt: 0,
      updatedAt: 0,
    );

    testWidgets('opening the ledger re-books a dose nobody touched', (
      tester,
    ) async {
      final notifications = FakeNotificationWriter();
      await pumpSalala(
        tester,
        notifications: notifications,
        resyncOnLaunch: true,
        seed: <Animal>[nala()],
        seedVaccinations: <Vaccination>[doseDueInDays(20)],
      );

      // Two clears plus the one alarm still ahead — and not one tap.
      await waitForSchedulerCalls(tester, notifications, 3);

      expect(notifications.written, hasLength(1));
      expect(notifications.written.single.title, 'Nala');
      expect(notifications.written.single.body, contains('Rabies'));
      expect(notifications.written.single.at.hour, reminderHour);
    });

    testWidgets('a dose whose morning has gone is not re-booked', (
      tester,
    ) async {
      final notifications = FakeNotificationWriter();
      await pumpSalala(
        tester,
        notifications: notifications,
        resyncOnLaunch: true,
        seed: <Animal>[nala()],
        // Read as overdue on the ledger, and quiet in the alarm manager.
        seedVaccinations: <Vaccination>[doseDueInDays(-3)],
      );

      await settleRealIo(tester);
      expect(notifications.log, isEmpty);
    });

    testWidgets('switching tabs does not book it all over again', (
      tester,
    ) async {
      final notifications = FakeNotificationWriter();
      await pumpSalala(
        tester,
        notifications: notifications,
        resyncOnLaunch: true,
        seed: <Animal>[nala()],
        seedVaccinations: <Vaccination>[doseDueInDays(20)],
      );
      await waitForSchedulerCalls(tester, notifications, 3);

      // The bar moves with `go`, which throws the animal list away and builds a
      // fresh one on the way back — so this is the round trip that would
      // re-reach the platform if the one-shot lived in the screen's own state.
      await tester.tap(find.widgetWithText(NavigationDestination, 'Litters'));
      await settleRealIo(tester);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Animals'));
      await settleRealIo(tester);

      expect(notifications.log, hasLength(3));
      expect(notifications.written, hasLength(1));
    });

    testWidgets('deleting the animal takes its alarms out of the phone', (
      tester,
    ) async {
      final notifications = FakeNotificationWriter();
      await pumpSalala(
        tester,
        notifications: notifications,
        resyncOnLaunch: true,
        seed: <Animal>[nala()],
        seedVaccinations: <Vaccination>[doseDueInDays(20)],
      );
      await waitForSchedulerCalls(tester, notifications, 3);
      expect(notifications.written, hasLength(1));

      // The card's own menu and its own confirm dialog: the delete the breeder
      // aims at is the one under test, not a DAO called behind the widget tree.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await waitForSchedulerCalls(tester, notifications, 4);

      // Cancelling by id was never going to work here: the rows those alarms were
      // booked from are gone with the animal, so nothing on the phone still names
      // them. The clear-all is what stops a dose of a dead animal's ledger from
      // waking the breeder at nine in the morning.
      expect(notifications.log.last, 'clearAll');
      expect(notifications.written, isEmpty);
      expect(find.text('Nala'), findsNothing);
    });
  });
}

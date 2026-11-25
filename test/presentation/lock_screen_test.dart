import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/services/app_lock_service.dart';

import '../helpers/fake_secure_storage.dart';
import '../helpers/pump_app.dart';

/// The gate is the one screen that can shut a breeder out of their own ledger, so
/// what these tests hold it to is *answering*: a keystore value that has gone bad
/// reads as "that PIN does not open this", never as a spinner that never ends.
void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  Future<void> gateOnPhone(WidgetTester tester) async {
    // A phone-shaped window: the default 800x600 test surface is shorter than the
    // gate, and a tap that misses its button would prove nothing about it.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'a PIN that does not match leaves the gate able to be tried again',
    (tester) async {
      await gateOnPhone(tester);
      final storage = await pumpApp(tester, hasPin: true);
      // A real enrollment, written the way the service writes it.
      storage.values['app_lock_salt'] = 'c2FsdHNhbHRzYWx0c2ExIA==';
      storage.values['app_lock_digest'] = 'a' * 64;

      await tester.enterText(find.byType(TextField), '1357');
      await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
      await settleRealIo(tester);

      expect(find.text('Wrong PIN'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Unlock'))
            .onPressed,
        isNotNull,
        reason: 'a wrong PIN is an answer, and the next one has to be askable',
      );
    },
  );

  testWidgets('a salt the keystore mangled does not weld the gate shut', (
    tester,
  ) async {
    await gateOnPhone(tester);
    final storage = await pumpApp(tester, hasPin: true);
    storage.values['app_lock_digest'] = 'a' * 64;
    // Half a value, or one the platform rewrote in some encoding of its own: it
    // is not a salt, and no PIN can be checked against it. Reading it used to
    // throw out of `verify`, and the screen kept its `_busy` flag set — a dead
    // button, a spinner, and a breeder with a PIN they could never submit again.
    storage.values['app_lock_salt'] = '!!!!';

    await tester.enterText(find.byType(TextField), '2481');
    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await settleRealIo(tester);

    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Unlock'))
          .onPressed,
      isNotNull,
      reason: 'the gate must stay able to answer the next PIN',
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  /// A gate with an enrollment nobody knows the PIN of, which is all the wrong
  /// answers below need: every try is a miss.
  Future<void> enrolledGate(WidgetTester tester) async {
    await gateOnPhone(tester);
    final storage = await pumpApp(tester, hasPin: true);
    storage.values['app_lock_salt'] = 'c2FsdHNhbHRzYWx0c2ExIA==';
    storage.values['app_lock_digest'] = 'a' * 64;
  }

  group('too many wrong PINs', () {
    testWidgets('close the gate for a countdown that runs down on its own', (
      tester,
    ) async {
      await enrolledGate(tester);

      Future<void> tryPin(String pin) async {
        await tester.enterText(find.byType(TextField), pin);
        await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
        await settleRealIo(tester);
      }

      for (var i = 0; i < 4; i++) {
        await tryPin('9999');
        expect(find.text('Wrong PIN'), findsOneWidget);
      }

      // The fifth is the one that stops the ask: the field goes quiet, the
      // button goes dead, and the sentence carries the seconds left.
      await tryPin('9999');
      expect(find.text('Wrong PIN'), findsNothing);
      expect(find.textContaining('Too many wrong PINs'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Unlock'))
            .onPressed,
        isNull,
        reason: 'the countdown is the lockout made visible, not decoration',
      );

      // The count is the screen's own timer: nothing is tapped to advance it.
      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      expect(find.textContaining('Too many wrong PINs'), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Unlock'))
            .onPressed,
        isNotNull,
        reason: 'a refusal that never ends is a lock nobody can open',
      );
    });

    testWidgets('a lockout that outlived the process opens on the refusal', (
      tester,
    ) async {
      await gateOnPhone(tester);
      final until = DateTime.now()
          .add(const Duration(minutes: 2))
          .millisecondsSinceEpoch;
      await pumpApp(
        tester,
        hasPin: true,
        secureSeed: <String, String>{
          'app_lock_salt': 'c2FsdHNhbHRzYWx0c2ExIA==',
          'app_lock_digest': 'a' * 64,
          'app_lock_locked_until': '$until',
        },
      );

      // No submit, no tap: the gate has to open already refusing, or killing the
      // app would be the way round the count.
      expect(find.textContaining('Too many wrong PINs'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Unlock'))
            .onPressed,
        isNull,
      );
    });
  });

  testWidgets('the PIN can be changed from settings with the current one', (
    tester,
  ) async {
    await gateOnPhone(tester);
    final storage = await pumpApp(tester, hasPin: true);
    // A real enrollment, written by the shipped service, so the whole flow is
    // exercised against the digest the phone would hold.
    await AppLockService(storage: storage).enable('1234');

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await settleRealIo(tester);
    expect(find.text('Companion is locked'), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();
    // The current PIN first: the row is not a way for whoever is holding an
    // unlocked phone to re-key it.
    await tester.enterText(
      find.widgetWithText(TextField, 'Current PIN'),
      '1234',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
    await settleRealIo(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Enter your PIN'),
      '5678',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Repeat the PIN'),
      '5678',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleRealIo(tester);

    expect(find.text('PIN changed.'), findsOneWidget);
    final lock = AppLockService(storage: storage);
    expect(await lock.verify('1234'), isFalse);
    expect(await lock.verify('5678'), isTrue);
  });

  group('coming back to the app', () {
    // Android sends the whole ladder, and Flutter asserts on a jump: leaving is
    // resumed -> inactive -> hidden -> paused, and coming back is the reverse.
    Future<void> leave(WidgetTester tester) async {
      for (final state in <AppLifecycleState>[
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
    }

    Future<void> comeBack(WidgetTester tester) async {
      for (final state in <AppLifecycleState>[
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
    }

    testWidgets('after the grace period the gate is shut again', (
      tester,
    ) async {
      await gateOnPhone(tester);
      final storage = await pumpApp(
        tester,
        hasPin: true,
        lockGrace: Duration.zero,
      );
      await unlockEnrolled(tester, storage);
      expect(find.text('Companion is locked'), findsNothing);

      await leave(tester);
      await comeBack(tester);

      expect(find.text('Companion is locked'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Unlock'),
        findsOneWidget,
        reason: 'the ledger is not left readable under the gate',
      );
    });

    testWidgets('a glance at a notification leaves the app open', (
      tester,
    ) async {
      await gateOnPhone(tester);
      final storage = await pumpApp(
        tester,
        hasPin: true,
        lockGrace: const Duration(hours: 1),
      );
      await unlockEnrolled(tester, storage);
      expect(find.text('Companion is locked'), findsNothing);

      await leave(tester);
      await comeBack(tester);

      expect(find.text('Companion is locked'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Unlock'), findsNothing);
    });
  });
}

/// Enrolls `1234` on the keystore and opens the gate with it.
Future<void> unlockEnrolled(
  WidgetTester tester,
  FakeSecureStorage storage,
) async {
  await AppLockService(storage: storage).enable('1234');
  await tester.enterText(find.byType(TextField), '1234');
  await tester.tap(find.widgetWithText(FilledButton, 'Unlock'));
  await settleRealIo(tester);
}

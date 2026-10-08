import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final storage = await pumpSalala(tester, hasPin: true);
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
    final storage = await pumpSalala(tester, hasPin: true);
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
}

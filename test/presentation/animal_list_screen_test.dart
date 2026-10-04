import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salala/data/models/animal.dart';
import 'package:salala/presentation/screens/animal_form_screen.dart';

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
    expect(
      find.text('Add animal'),
      findsNWidgets(2),
    ); // FAB + empty-state button
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

    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add animal'));
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
}

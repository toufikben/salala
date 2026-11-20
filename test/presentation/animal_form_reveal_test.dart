import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/presentation/screens/animal_form_screen.dart';

import '../helpers/pump_app.dart';

/// What a breeder is left with when the form refuses and says nothing in the
/// place she is looking at.
///
/// The phone measured this (Stage 5d): the dump taken after `حفظ` was byte
/// identical to the one before it, because the error text is painted under the
/// first field and the Save pill is at the bottom of a form taller than the
/// screen. The test that already lives in `animal_list_screen_test.dart` asserts
/// `find.text('A name is required')` and was green the whole time — `find.text`
/// answers for widgets in the tree, not for widgets a human can see. So these
/// assertions are about rects.
void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  Future<void> openAnimalForm(WidgetTester tester) async {
    // A short phone on purpose. On the 2400px-tall surface the shipped-form tests
    // use, the form is only ~66px taller than the viewport, so scrolling to the
    // end hides the Name box but leaves Species — the second field — still on
    // screen, and a precondition about Species would assert nothing. At 1920px
    // there is enough overflow that both top boxes genuinely leave the viewport.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Add animal'));
    await tester.pumpAndSettle();
  }

  bool insideTheForm(WidgetTester tester, Finder field) {
    final rect = tester.getRect(field);
    final viewport = tester.getRect(find.byType(SingleChildScrollView).first);
    return rect.top >= viewport.top && rect.bottom <= viewport.bottom;
  }

  // Scrolled to the end by the position, not by ensureVisible: a focused field
  // re-asserts its own visibility on the next frame, so a helper that scrolls
  // "until the button is visible" can leave the top boxes on screen and the
  // precondition below would then be asserting nothing.
  Future<void> scrollToEnd(WidgetTester tester) async {
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
  }

  testWidgets('a save refused for no name scrolls the name box back into view', (
    tester,
  ) async {
    await openAnimalForm(tester);

    final name = find.widgetWithText(TextFormField, 'Name');
    final save = find.widgetWithText(FilledButton, 'Save');
    await scrollToEnd(tester);

    // The precondition, asserted rather than assumed: without it the test would
    // also pass on a build that never scrolled anywhere.
    expect(insideTheForm(tester, name), isFalse);

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(find.text('A name is required'), findsOneWidget);
    expect(
      insideTheForm(tester, name),
      isTrue,
      reason: 'the box that was refused has to be the box on screen',
    );
    expect(find.byType(AnimalFormScreen), findsOneWidget);
  });

  testWidgets(
    'with a name already typed, it is the species box that comes back',
    (tester) async {
      await openAnimalForm(tester);

      // Filled without focusing: `enterText` focuses the box, and a focused
      // field pulls itself back into view whenever the viewport moves, which
      // would undo the scroll below and leave the precondition asserting
      // nothing. The controller is the same one `_save()` reads.
      tester
              .widget<TextFormField>(find.widgetWithText(TextFormField, 'Name'))
              .controller!
              .text =
          'Nala';
      await tester.pumpAndSettle();
      final species = find.widgetWithText(TextFormField, 'Species');
      final save = find.widgetWithText(FilledButton, 'Save');
      await scrollToEnd(tester);
      expect(insideTheForm(tester, species), isFalse);

      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(find.text('Choose a species'), findsOneWidget);
      expect(
        insideTheForm(tester, species),
        isTrue,
        reason: 'the box that was refused has to be the box on screen',
      );
      // The field that answered is the first refusing one, not the first field:
      // a name already filled in must not be what the screen drags her back to.
      expect(tester.widget<TextFormField>(species).controller!.text, isEmpty);
    },
  );

  testWidgets(
    'the refusal sentence leaves the moment the box is filled',
    (tester) async {
      await openAnimalForm(tester);

      final save = find.widgetWithText(FilledButton, 'Save');
      await scrollToEnd(tester);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('A name is required'), findsOneWidget);

      // Typed into, not merely set: `onUserInteraction` is the promise that a
      // keystroke re-validates, and a controller written from the outside would
      // pass this test while the phone stayed broken.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Name'),
        'Nala',
      );
      await tester.pumpAndSettle();

      // Measured on the phone: the sentence used to outlive the text that fixed
      // it, and a breeder who had done the right thing was still being told she
      // had not.
      expect(find.text('A name is required'), findsNothing);
      expect(find.text('Choose a species'), findsOneWidget);
    },
  );
}

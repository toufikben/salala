import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/core/build_info.dart';
import 'package:companion/core/contact.dart';
import 'package:companion/data/models/animal.dart';
import 'package:companion/presentation/providers/record_providers.dart';
import 'package:companion/presentation/screens/about_screen.dart';
import 'package:companion/presentation/screens/animal_form_screen.dart';
import 'package:companion/presentation/screens/help_screen.dart';
import 'package:companion/presentation/screens/onboarding_screen.dart';
import 'package:companion/presentation/screens/privacy_screen.dart';
import 'package:companion/presentation/screens/settings_screen.dart';
import 'package:companion/presentation/screens/terms_screen.dart';
import 'package:companion/presentation/screens/whats_new_screen.dart';

import '../helpers/fake_review_service.dart';
import '../helpers/pump_app.dart';

Animal animal(String name) => Animal(
  id: name.toLowerCase(),
  name: name,
  species: 'dog',
  sex: Sex.male,
  status: AnimalStatus.active,
  isBreedingStock: false,
  createdAt: 0,
  updatedAt: 0,
);

/// Opens Settings and taps a row by its label.
///
/// The list is longer than a phone now — three groups and eleven rows — so a row
/// at the bottom does not exist until the list is scrolled to it: a `ListView` is
/// lazy, and `ensureVisible` on a row that has never been built throws "No
/// element" rather than scrolling.
Future<void> openSetting(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
  await settleRealIo(tester);

  final row = find.text(label);
  await tester.scrollUntilVisible(
    row,
    180,
    scrollable: find
        .descendant(
          of: find.byType(SettingsScreen),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pump();
  await tester.tap(row);
  await settleRealIo(tester);
}

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;

  group('the pages behind Settings', () {
    testWidgets('About names the version and offers the licences', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, 'About');

      expect(find.byType(AboutScreen), findsOneWidget);
      expect(find.text('Version $appVersion'), findsOneWidget);
      // The licensing row is the app's legal obligation to every package it
      // bundles, and `showLicensePage` is the mechanism Flutter provides.
      expect(find.text('Open-source licences'), findsOneWidget);
    });

    testWidgets('About lists the licences when the row is tapped', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, 'About');

      await tester.tap(find.text('Open-source licences'));
      await tester.pumpAndSettle();

      // Flutter's own license page, drawn by the framework.
      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('Privacy says what leaves the phone and what is collected', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, 'Privacy');

      expect(find.byType(PrivacyScreen), findsOneWidget);
      // The two halves of the promise. The second one is the one an app can
      // quietly drop: a backup carries buyers' names, and the page has to say so
      // rather than only saying "nothing is collected".
      expect(find.textContaining('export'), findsWidgets);
      expect(find.textContaining('Nothing.'), findsOneWidget);
    });

    testWidgets('Terms refuses to be veterinary advice', (tester) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, 'Terms of use');

      expect(find.byType(TermsScreen), findsOneWidget);
      expect(find.textContaining('not veterinary advice'), findsNothing);
      // The heading is a sentence of its own, so it is checked as one.
      expect(find.text('Not veterinary advice'), findsOneWidget);
    });

    testWidgets('Help answers the questions that lose data', (tester) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, 'Help');

      expect(find.byType(HelpScreen), findsOneWidget);
      // Collapsed by default: eight answers at once is a wall, and the page is
      // meant to be scanned for one.
      expect(find.textContaining('It cannot be recovered'), findsNothing);

      await tester.tap(find.text('I forgot my PIN'));
      await tester.pumpAndSettle();

      expect(find.textContaining('It cannot be recovered'), findsOneWidget);
    });

    testWidgets('Help shows the address to write to', (tester) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, 'Help');

      final address = find.text(AppContact.supportEmail);
      await tester.scrollUntilVisible(
        address,
        180,
        scrollable: find
            .descendant(
              of: find.byType(HelpScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();

      expect(address, findsOneWidget);
    });

    testWidgets('What\'s new lists the release and its version', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, "What's new");

      expect(find.byType(WhatsNewScreen), findsOneWidget);
      expect(find.textContaining('Five more languages'), findsOneWidget);
      expect(find.text('Version $appVersion'), findsOneWidget);
    });

    testWidgets('back from a page returns to Settings, not to the herd', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, 'Privacy');

      await tester.pageBack();
      await settleRealIo(tester);

      // A page pushed from Settings belongs under Settings: landing in the herd
      // would lose the breeder's place in a list she was working through.
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });

  group('the introduction', () {
    testWidgets('a fresh install meets the slides before the herd', (
      tester,
    ) async {
      await pumpApp(tester, onboardingSeen: false);

      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('One record per animal'), findsOneWidget);
      expect(find.text('No animals yet'), findsNothing);
    });

    testWidgets('the eight cards walk to the herd and stay gone', (
      tester,
    ) async {
      await pumpApp(tester, onboardingSeen: false);

      // One card per thing the app holds, in the order a breeder meets them.
      const cards = <String>[
        'One record per animal',
        'Every litter, from mating to weaning',
        'The pedigree on one page',
        'Its health, in order',
        'Who is waiting, who has paid',
        'Its story travels with it',
        "Nobody else's server",
      ];
      for (final title in cards) {
        expect(find.text(title), findsOneWidget, reason: 'card "$title"');
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // The last card is not a feature: it is the answer to why this costs
      // money, and it has to be the last thing rather than the first.
      expect(find.text('Made by one person'), findsOneWidget);
      expect(find.text('Add my first animal'), findsOneWidget);

      await tester.tap(find.text('Add my first animal'));
      await settleUntil(
        tester,
        () => find.byType(AnimalFormScreen).evaluate().isNotEmpty,
      );
      await settleRealIo(tester);

      // The herd page stays alive under the form, and this is the first frame
      // it ever builds: the handovers query it watches starts here, not when
      // the app opened. A query still in flight when the test ends leaves
      // sqflite's ten-second transaction-lock timer pending and fails teardown
      // even though every assertion passed (run 45226258616). Waiting on the
      // query's own result is the outcome rather than another guess at a round
      // count; the subscription is held open so the auto-dispose provider is
      // not torn down and re-asked between pumps.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(AnimalFormScreen)),
        listen: false,
      );
      final handovers = container.listen(
        placementsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      await settleUntil(tester, () {
        final handovers = container.read(placementsProvider);
        // Either answer means the query is done: this wait is about the
        // transaction lock, not about what the herd holds, and the assertion
        // below is about the route.
        return handovers.hasValue || handovers.hasError;
      });
      handovers.close();

      // The button promised the form, so the form is what it must open — not an
      // empty herd asking her to tap "Add animal" a second time. The row was
      // written too, so this is not just a route change: the intro is a setting
      // now, and Settings can put it back.
      expect(find.byType(AnimalFormScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('skipping marks it seen rather than leaving a loop', (
      tester,
    ) async {
      await pumpApp(tester, onboardingSeen: false);

      await tester.tap(find.text('Skip'));
      // Waited on by the outcome, not by a round count: the skip writes a
      // setting and the home page reads it back on another isolate, and a loaded
      // machine can need longer than `settleRealIo`'s fixed rounds. That is how
      // this passed alone and failed inside a suite (run 45027240456).
      await settleUntil(
        tester,
        () => find.text('No animals yet').evaluate().isNotEmpty,
      );
      await settleRealIo(tester);

      expect(find.text('No animals yet'), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('Settings reopens the slides and returns here afterwards', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[animal('Atlas')]);
      await openSetting(tester, 'Show the introduction again');

      expect(find.byType(OnboardingScreen), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await settleRealIo(tester);

      // Done from Settings goes back to Settings. The slides were reopened to be
      // read, not to restart the app on a breeder who was already running it.
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Atlas'), findsNothing);
    });
  });

  group('the rating row', () {
    testWidgets('asks the store for its card', (tester) async {
      final review = FakeReviewService();
      await pumpApp(tester, seed: <Animal>[animal('Atlas')], review: review);
      await openSetting(tester, 'Rate Companion');

      expect(review.requests, 1);
      // A card that was shown needs no sentence: the store's own dialog is on
      // screen, and a snackbar behind it would be the app talking over it.
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a phone with no card opens the listing and says nothing', (
      tester,
    ) async {
      // The real service opens the store page and returns false in this case.
      // That is still what the breeder asked for, so silence is the right answer
      // — an apology here would read as a failure that did not happen.
      final review = FakeReviewService(cards: false);
      await pumpApp(tester, seed: <Animal>[animal('Atlas')], review: review);
      await openSetting(tester, 'Rate Companion');

      expect(review.requests, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a phone that refuses the request says so', (tester) async {
      final review = FakeReviewService()
        ..failure = UnsupportedError('no store on this phone');
      await pumpApp(tester, seed: <Animal>[animal('Atlas')], review: review);
      await openSetting(tester, 'Rate Companion');

      expect(
        find.text('This phone cannot show the review card right now.'),
        findsOneWidget,
      );
    });

    testWidgets('a second tap while the first is in flight asks once', (
      tester,
    ) async {
      // The request is held open, because the state this guard exists for is one
      // where the first call has not answered yet. Without the gate the fake
      // completes in a microtask that `tester.tap`'s own awaits flush, so the
      // second tap arrives after the row has already gone idle — and the test
      // would be asserting on a race that never happens on a real phone.
      final review = FakeReviewService()..gate = Completer<void>();
      await pumpApp(tester, seed: <Animal>[animal('Atlas')], review: review);
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await settleRealIo(tester);

      final row = find.text('Rate Companion');
      await tester.scrollUntilVisible(
        row,
        180,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();

      await tester.tap(row);
      await tester.tap(row);

      expect(review.requests, 1);

      review.gate!.complete();
      await settleRealIo(tester);
      expect(review.requests, 1);
    });
  });
}

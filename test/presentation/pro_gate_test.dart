import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/data/models/animal.dart';
import 'package:companion/data/models/photo.dart';
import 'package:companion/presentation/screens/animal_detail_screen.dart';
import 'package:companion/presentation/screens/settings_screen.dart';
import 'package:companion/presentation/screens/upgrade_screen.dart';
import 'package:companion/services/billing.dart';
import 'package:companion/services/trial.dart';

import '../helpers/pump_app.dart';

/// The gates have to be exercised with billing closed and open, because the
/// shipped build sells: a phone inside its trial sees none of them, and the ones
/// that open after expiry are code no test would otherwise run.
const String _nalaId = 'animal-nala';

Animal _nala() => Animal(
  id: _nalaId,
  name: 'Nala',
  species: 'dog',
  breed: 'Border collie',
  sex: Sex.female,
  status: AnimalStatus.active,
  isBreedingStock: true,
  birthDate: DateTime(2024, 5, 12).millisecondsSinceEpoch,
  createdAt: 0,
  updatedAt: 0,
);

Photo _picture(int index) => Photo(
  id: '',
  animalId: _nalaId,
  fileName: 'shot$index.jpg-1024',
  createdAt: 0,
);

ProAccess _over() => const ProAccess(
  billingEnabled: true,
  owned: Entitlement.none(),
  trial: TrialState(daysLeft: 0, expired: true),
);

ProAccess _paid() => ProAccess(
  billingEnabled: true,
  owned: const Entitlement(<CompanionPlan>{CompanionPlan.pro}),
  trial: const TrialState(daysLeft: 0, expired: true),
);

Future<void> _openNala(WidgetTester tester) async {
  await tester.tap(find.text('Nala'));
  await settleRealIo(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.descendant(
        of: find.byType(AnimalDetailScreen),
        matching: find.byType(Scrollable),
      ),
    );
    await settleRealIo(tester);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await settleRealIo(tester);
}

/// Opens Settings and taps a row at the bottom of a lazy list.
///
/// The statistics row lives under the export and CSV groups, so it is not
/// built until the list is scrolled: `find.text` finds nothing and a tap on
/// nothing throws before the gate is ever asked.
Future<void> _openSetting(WidgetTester tester, String label) async {
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
  group('the photo allowance', () {
    testWidgets('a phone inside its trial asks for nothing', (tester) async {
      await pumpApp(
        tester,
        seed: <Animal>[_nala()],
        seedPhotos: <Photo>[_picture(1), _picture(2), _picture(3)],
      );
      await _openNala(tester);
      await _tap(tester, find.widgetWithText(TextButton, 'Add photo'));

      expect(find.text('Choose from the gallery'), findsOneWidget);
      expect(find.text('Unlimited photos is part of Pro'), findsNothing);
    });

    testWidgets('the fourth photo asks, and the plans open from there', (
      tester,
    ) async {
      await pumpApp(
        tester,
        seed: <Animal>[_nala()],
        seedPhotos: <Photo>[_picture(1), _picture(2), _picture(3)],
        proAccess: _over(),
      );
      await _openNala(tester);
      await _tap(tester, find.widgetWithText(TextButton, 'Add photo'));

      // The sheet, not the picker: a breeder must not be sent to the gallery to
      // choose a file the app would then refuse to keep.
      expect(find.text('Unlimited photos is part of Pro'), findsOneWidget);
      expect(find.text('Choose from the gallery'), findsNothing);

      await tester.tap(find.text('See the plans'));
      await settleRealIo(tester);

      expect(find.byType(UpgradeScreen), findsOneWidget);
      // The page opens on the question she asked, not on a generic pitch.
      expect(find.text('Unlimited photos is part of Pro'), findsOneWidget);
    });

    testWidgets('a breeder who paid is never asked', (tester) async {
      await pumpApp(
        tester,
        seed: <Animal>[_nala()],
        seedPhotos: <Photo>[_picture(1), _picture(2), _picture(3)],
        proAccess: _paid(),
      );
      await _openNala(tester);
      await _tap(tester, find.widgetWithText(TextButton, 'Add photo'));

      expect(find.text('Choose from the gallery'), findsOneWidget);
    });

    testWidgets('the third photo is still free', (tester) async {
      await pumpApp(
        tester,
        seed: <Animal>[_nala()],
        seedPhotos: <Photo>[_picture(1), _picture(2)],
        proAccess: _over(),
      );
      await _openNala(tester);
      await _tap(tester, find.widgetWithText(TextButton, 'Add photo'));

      expect(find.text('Choose from the gallery'), findsOneWidget);
    });
  });

  group('the buyer PDF', () {
    testWidgets('asks before it builds, not after', (tester) async {
      await pumpApp(tester, seed: <Animal>[_nala()], proAccess: _over());
      await _openNala(tester);
      await _tap(tester, find.byTooltip('PDF pack'));

      expect(find.text('Branded reports is part of Pro'), findsOneWidget);
    });

    testWidgets('a paying breeder gets the share sheet instead', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[_nala()], proAccess: _paid());
      await _openNala(tester);
      await _tap(tester, find.byTooltip('PDF pack'));

      expect(find.text('Branded reports is part of Pro'), findsNothing);
    });
  });

  group('the statistics page', () {
    testWidgets('asks before it opens, not after', (tester) async {
      await pumpApp(tester, seed: <Animal>[_nala()], proAccess: _over());
      await _openSetting(tester, 'The kennel in numbers');

      expect(find.text('The kennel statistics is part of Pro'), findsOneWidget);
    });

    testWidgets('a paying breeder opens the page', (tester) async {
      await pumpApp(tester, seed: <Animal>[_nala()], proAccess: _paid());
      await _openSetting(tester, 'The kennel in numbers');

      expect(find.text('The kennel statistics is part of Pro'), findsNothing);
    });
  });

  // Both of these were found on the phone, after a real test-card purchase:
  // the app kept selling a plan it had just sold, and kept counting down a
  // trial that was no longer what governed the app.
  group('after the money is taken', () {
    testWidgets('the upgrade page stops selling what she already owns', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[_nala()], proAccess: _paid());
      await _openSetting(tester, 'Companion Pro');

      expect(find.byType(UpgradeScreen), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Subscribe'), findsNothing);
      expect(find.text('Restore a purchase'), findsNothing);
      // The truth is still on the page, so she knows the tap landed.
      expect(find.text('Thank you. Everything is unlocked.'), findsOneWidget);
    });

    testWidgets('Settings stops counting down a trial she has bought out of', (
      tester,
    ) async {
      await pumpApp(tester, seed: <Animal>[_nala()], proAccess: _paid());
      await tester.tap(find.widgetWithText(NavigationDestination, 'Settings'));
      await settleRealIo(tester);

      expect(find.text('Active on this phone'), findsOneWidget);
      // The Pro row and the trial row sat one above the other saying two
      // different things; only the Pro row survives.
      expect(find.text('Free trial'), findsNothing);
      expect(find.textContaining('days left'), findsNothing);
    });
  });
}

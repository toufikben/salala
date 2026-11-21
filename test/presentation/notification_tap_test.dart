import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:companion/app.dart';
import 'package:companion/data/models/animal.dart';
import 'package:companion/presentation/providers/app_providers.dart';
import 'package:companion/presentation/screens/animal_detail_screen.dart';

import '../helpers/pump_app.dart';

/// A reminder says "Rabies is due" and puts the dog's name in its title, so the
/// breeder who taps it is asking about *that dog*. These tests are the two
/// halves of the answer: the payload the alarm carries, and where the app goes
/// when it arrives.
const String _nalaId = 'animal-nala';

Animal _nala() => Animal(
  id: _nalaId,
  name: 'Nala',
  species: 'dog',
  breed: 'Border collie',
  sex: Sex.female,
  status: AnimalStatus.active,
  createdAt: 0,
  updatedAt: 0,
);

/// The container the pumped app is actually using, so a test can hand the app
/// the same thing `main()` hands it when the phone reports a launch payload.
ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(CompanionApp)));

void main() {
  testWidgets('a tapped reminder opens the animal it is about', (tester) async {
    await pumpApp(tester, seed: <Animal>[_nala()]);
    expect(find.byType(AnimalDetailScreen), findsNothing);

    _container(tester).read(pendingAnimalTapProvider.notifier).set(_nalaId);
    await settleRealIo(tester);

    expect(find.byType(AnimalDetailScreen), findsOneWidget);
    // The ledger, not the herd: the tap is answered with the dog rather than
    // with a list the breeder then has to look her up in.
    expect(find.text('dog · Border collie · Female'), findsOneWidget);
  });

  testWidgets('the tap is spent once, so leaving the ledger stays left', (
    tester,
  ) async {
    await pumpApp(tester, seed: <Animal>[_nala()]);

    final container = _container(tester);
    container.read(pendingAnimalTapProvider.notifier).set(_nalaId);
    await settleRealIo(tester);
    expect(find.byType(AnimalDetailScreen), findsOneWidget);

    // Back to the herd by hand. A tap that was replayed on every rebuild would
    // drag the breeder straight back into the ledger she just left.
    await tester.pageBack();
    await settleRealIo(tester);
    expect(find.byType(AnimalDetailScreen), findsNothing);
    expect(container.read(pendingAnimalTapProvider), isNull);
  });

  testWidgets('a locked phone answers the tap with the PIN, then the dog', (
    tester,
  ) async {
    await pumpApp(tester, hasPin: true, seed: <Animal>[_nala()]);
    final container = _container(tester);

    expect(find.text('Companion is locked'), findsOneWidget);

    container.read(pendingAnimalTapProvider.notifier).set(_nalaId);
    await tester.pumpAndSettle();

    // The gate holds: the alert is remembered, not forced through a lock. This
    // is the whole reason the payload is a provider rather than a `go` at the
    // moment of the tap.
    expect(find.text('Companion is locked'), findsOneWidget);
    expect(find.byType(AnimalDetailScreen), findsNothing);
    expect(container.read(pendingAnimalTapProvider), _nalaId);

    container.read(lockGateProvider.notifier).unlock();
    await settleRealIo(tester);
    // The herd screen is built for a frame on the way through, and its agenda
    // query is a database read like any other: answered here so the test does
    // not end on top of it.
    await settleRealIo(tester);

    expect(find.byType(AnimalDetailScreen), findsOneWidget);
    expect(container.read(pendingAnimalTapProvider), isNull);
  });

  testWidgets('an alert for an animal that is gone lands on her own page', (
    tester,
  ) async {
    // Deleted between the alarm being written and the thumb landing on it — a
    // week is plenty of time for that. The id still opens a screen, which is
    // what makes the answer "this animal was deleted" instead of a blank app.
    await pumpApp(tester, seed: <Animal>[_nala()]);

    _container(tester).read(pendingAnimalTapProvider.notifier).set('animal-x');
    await settleRealIo(tester);

    expect(find.byType(AnimalDetailScreen), findsOneWidget);
    // Twice on purpose: the page's title and its body both say it, which is the
    // screen doing what it already does for an animal deleted under it.
    expect(find.text('This animal was deleted.'), findsNWidgets(2));
  });
}

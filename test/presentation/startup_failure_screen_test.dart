import 'package:flutter_test/flutter_test.dart';
import 'package:salala/presentation/screens/startup_failure_screen.dart';

/// The screen a breeder sees when the launch itself failed — which is the one
/// moment the app has no database, no settings row, and therefore no stored
/// language to read. So it is pumped bare, and its wording is the only claim.
void main() {
  group('the startup failure', () {
    testWidgets('a ledger the phone would not open still says so', (
      tester,
    ) async {
      await tester.pumpWidget(const StartupFailureScreen());
      await tester.pumpAndSettle();

      expect(
        find.text('Salala could not open the ledger on this phone.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your records are still in the file. Close the app and open it again.',
        ),
        findsOneWidget,
      );
    });
  });
}

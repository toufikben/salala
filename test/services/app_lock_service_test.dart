import 'package:flutter_test/flutter_test.dart';
import 'package:salala/services/app_lock_service.dart';

import '../helpers/fake_secure_storage.dart';

/// The lock's arithmetic, away from any screen: how many tries, how long, and
/// what survives the process dying. These numbers decide whether a phone left on
/// a table can be guessed open, so they are asserted directly rather than
/// through a countdown somebody has to watch.
void main() {
  late FakeSecureStorage storage;
  late DateTime now;
  late AppLockService service;

  setUp(() {
    storage = FakeSecureStorage();
    now = DateTime(2026, 5, 1, 9);
    service = AppLockService(storage: storage, clock: () => now);
  });

  /// Answers one wrong PIN and steps past whatever it refused for, so the next
  /// call is a fresh try rather than the lockout echoing itself back.
  Future<PinAttempt> wrongThenWait() async {
    final answer = await service.attempt('0000');
    if (answer.retryAfter case final wait?) {
      now = now.add(wait);
    }
    return answer;
  }

  test('a correct PIN opens the gate and forgets the wrong ones before it', () async {
    await service.enable('1234');

    expect((await service.attempt('9999')).accepted, isFalse);
    expect((await service.attempt('1234')).accepted, isTrue);
    expect(storage.values.containsKey('app_lock_failures'), isFalse);
    expect(storage.values.containsKey('app_lock_locked_until'), isFalse);

    // The count started again: four more wrong answers are still ordinary ones.
    for (var i = 0; i < 4; i++) {
      expect((await wrongThenWait()).retryAfter, isNull);
    }
  });

  test('the fifth wrong PIN refuses for thirty seconds, and a restart remembers', () async {
    await service.enable('1234');

    for (var i = 0; i < 4; i++) {
      expect((await wrongThenWait()).retryAfter, isNull);
    }
    final fifth = await service.attempt('0000');
    expect(fifth.accepted, isFalse);
    expect(fifth.retryAfter, const Duration(seconds: 30));

    // A new service over the same keystore is what a killed app looks like: the
    // refusal has to be there, or force-stopping the app is a free retry.
    final restarted = AppLockService(storage: storage, clock: () => now);
    expect(await restarted.lockoutRemaining(), isNotNull);
  });

  test('a correct PIN during the lockout is still refused', () async {
    await service.enable('1234');
    for (var i = 0; i < 5; i++) {
      await service.attempt('0000');
    }

    final answer = await service.attempt('1234');
    expect(answer.accepted, isFalse);
    expect(answer.retryAfter, isNotNull);
  });

  test('the refusal doubles, then stops at fifteen minutes', () async {
    await service.enable('1234');

    final waits = <Duration?>[];
    for (var i = 0; i < 12; i++) {
      waits.add((await wrongThenWait()).retryAfter);
    }

    expect(waits.sublist(0, 4), everyElement(isNull));
    expect(waits[4], const Duration(seconds: 30));
    expect(waits[5], const Duration(seconds: 60));
    expect(waits[6], const Duration(seconds: 120));
    expect(waits[7], const Duration(seconds: 240));
    expect(waits[8], const Duration(seconds: 480));
    expect(waits[9], const Duration(minutes: 15));
    expect(waits[10], const Duration(minutes: 15));
    expect(waits[11], const Duration(minutes: 15));
  });

  test('the gate answers again once the lockout has run out', () async {
    await service.enable('1234');
    for (var i = 0; i < 5; i++) {
      await service.attempt('0000');
    }
    expect(await service.lockoutRemaining(), const Duration(seconds: 30));

    now = now.add(const Duration(seconds: 31));
    expect(await service.lockoutRemaining(), isNull);
    expect((await service.attempt('1234')).accepted, isTrue);
    expect(storage.values.containsKey('app_lock_failures'), isFalse);
  });

  test(
    'changing the PIN needs the current one, and the old one stops working',
    () async {
      await service.enable('1234');

      await expectLater(
        service.change('0000', '5678'),
        throwsA(isA<AppLockException>()),
      );

      await service.change('1234', '5678');
      expect(await service.verify('1234'), isFalse);
      expect(await service.verify('5678'), isTrue);
    },
  );
}

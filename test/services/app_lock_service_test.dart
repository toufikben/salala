import 'package:flutter_test/flutter_test.dart';
import 'package:salala/services/app_lock_service.dart';

import '../helpers/fake_secure_storage.dart';

void main() {
  late FakeSecureStorage storage;
  late AppLockService lock;

  setUp(() {
    storage = FakeSecureStorage();
    lock = AppLockService(storage: storage);
  });

  group('AppLockService', () {
    test('no PIN means the app opens unlocked', () async {
      expect(await lock.isLocked(), isFalse);
      expect(await lock.verify('1234'), isFalse);
    });

    test('enabling a PIN locks the app', () async {
      await lock.enable('2481');
      expect(await lock.isLocked(), isTrue);
      expect(await lock.verify('2481'), isTrue);
      expect(await lock.verify('2482'), isFalse);
    });

    test('a PIN shorter than four digits is rejected', () async {
      await expectLater(lock.enable('12'), throwsA(isA<AppLockException>()));
      expect(await lock.isLocked(), isFalse);
    });

    test('the raw PIN never reaches storage', () async {
      await lock.enable('2481');
      expect(storage.values.values.every((v) => !v.contains('2481')), isTrue);
      expect(storage.values.length, 2, reason: 'one salt, one digest');
    });

    test(
      'the same PIN hashes differently per install because of the salt',
      () async {
        await lock.enable('2481');
        final firstDigest = storage.values['app_lock_digest'];

        await lock.disable();
        await lock.enable('2481');
        expect(storage.values['app_lock_digest'], isNot(firstDigest));
        expect(await lock.verify('2481'), isTrue);
      },
    );

    test('changing the PIN requires knowing the current one', () async {
      await lock.enable('2481');
      await expectLater(
        lock.change('0000', '1357'),
        throwsA(isA<AppLockException>()),
      );
      expect(
        await lock.verify('2481'),
        isTrue,
        reason: 'a failed change must not overwrite',
      );

      await lock.change('2481', '1357');
      expect(await lock.verify('1357'), isTrue);
      expect(await lock.verify('2481'), isFalse);
    });

    test('disabling removes both the salt and the digest', () async {
      await lock.enable('2481');
      await lock.disable();
      expect(await lock.isLocked(), isFalse);
      expect(storage.values, isEmpty);
    });
  });
}

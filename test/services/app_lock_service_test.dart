import 'dart:convert';

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
      // The values' shapes are checked instead of scanning them for the PIN's
      // digits: a digest is 64 hex characters, and about one in a thousand of
      // them contain any given four of them, which is how this assertion failed
      // on a run whose only change was documentation (CI 37828225501). Two keys,
      // a 16-byte salt and a 64-character hex digest cannot hold a typed PIN.
      expect(
        storage.values.keys,
        unorderedEquals(<String>['app_lock_salt', 'app_lock_digest']),
      );
      expect(base64Decode(storage.values['app_lock_salt']!), hasLength(16));
      expect(
        storage.values['app_lock_digest']!,
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
    });

    test('a salt that cannot be decoded answers no, not a crash', () async {
      await lock.enable('2481');
      // A keystore value that came back half-written is not a salt, and
      // `base64Decode` throws on one. The screen asked a yes-or-no question, so
      // that is the only shape the answer may take: an exception here used to
      // reach the unlock screen and leave it unable to take another PIN.
      storage.values['app_lock_salt'] = '!!!!';

      expect(await lock.verify('2481'), isFalse);
      expect(await lock.isLocked(), isTrue);
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

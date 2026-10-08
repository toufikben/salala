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

    test('a digest with no salt behind it can never be unlocked', () async {
      await lock.enable('2481');
      // The residue the old delete order left behind when the keystore refused
      // halfway: `isLocked()` reads the digest alone, so the unlock screen
      // opens, and `verify()` has no salt to hash against, so it answers no to
      // every PIN the breeder can type. The records are still on the phone and
      // unreachable — the only way out is a restore. The salt is removed by hand
      // because no order of the current code can produce it any more: this case
      // names the dead end so the ordering above has something to be for.
      storage.values.remove('app_lock_salt');

      expect(await lock.isLocked(), isTrue);
      expect(await lock.verify('2481'), isFalse);
      await expectLater(
        lock.change('2481', '1357'),
        throwsA(isA<AppLockException>()),
      );
    });

    test(
      'a disable the keystore refuses halfway leaves the app open',
      () async {
        await lock.enable('2481');
        storage.deleteRefused.add('app_lock_salt');

        await expectLater(lock.disable(), throwsStateError);

        // The digest goes first, so the worst a refusal can leave is the salt of a
        // lock that no longer exists: nothing reads it, and the app opens.
        expect(await lock.isLocked(), isFalse);
        expect(storage.values.keys, unorderedEquals(<String>['app_lock_salt']));
      },
    );

    test('a PIN the keystore refuses to finish leaves the app open', () async {
      // The write side of the same rule: the digest is taken off before the salt
      // goes in, so a halfway write can only leave a salt nothing reads. This
      // case starts unlocked, where both orders agree — the next test is the one
      // that can tell them apart.
      storage.writeRefused.add('app_lock_digest');

      await expectLater(lock.enable('2481'), throwsStateError);

      expect(await lock.isLocked(), isFalse);
    });

    test(
      'a PIN change the phone refuses mid-way does not brick the lock',
      () async {
        // `change()` reaches `enable` with an old digest still on the phone, which
        // is the one place salt-then-digest was ever dangerous: the salt gets
        // rewritten, the digest write is refused, and the old digest is left behind
        // a salt that cannot reproduce it. The dead end above, reached by a halfway
        // write instead of a halfway delete — and this test fails against it.
        await lock.enable('2481');
        expect(await lock.verify('2481'), isTrue);
        storage.writeRefused.add('app_lock_digest');

        await expectLater(lock.change('2481', '1357'), throwsStateError);

        expect(await lock.isLocked(), isFalse);
        expect(await lock.verify('2481'), isFalse);
        expect(await lock.verify('1357'), isFalse);
        expect(storage.values.keys, unorderedEquals(<String>['app_lock_salt']));
      },
    );
  });
}

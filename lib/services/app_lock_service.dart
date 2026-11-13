import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// App-lock PIN, stored as a salted SHA-256 digest in the device keystore-backed
/// secure storage. This replaces SQLCipher for Phase 0-2: it stops the casual
/// shoulder-surf while keeping the database itself testable and unbrickable
/// (a lost key cannot lock a breeder out of their records forever).
///
/// The PIN is never logged, never exported, and never sent anywhere.
class AppLockService {
  AppLockService({FlutterSecureStorage? storage, DateTime Function()? clock})
    : _storage = storage ?? _defaultStorage,
      _clock = clock ?? DateTime.now;

  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    // iOS: `first_unlock_this_device` keeps the digest on the device it was
    // enrolled on, so a new phone asks for a new PIN instead of shipping the
    // old hash along in an iCloud restore. Android backup rules are handled in
    // the manifest (`dataExtractionRules`), not here.
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _saltKey = 'app_lock_salt';
  static const String _digestKey = 'app_lock_digest';
  static const String _failuresKey = 'app_lock_failures';
  static const String _lockedUntilKey = 'app_lock_locked_until';

  /// Wrong PINs allowed before the gate starts to refuse for a while.
  static const int failuresBeforeLockout = 5;

  /// The first refusal, doubling with every wrong PIN after it.
  static const Duration firstLockout = Duration(seconds: 30);

  /// The ceiling, so a stolen phone cannot be parked forever behind a guess and
  /// its owner is never locked out of their own records for an afternoon.
  static const Duration maxLockout = Duration(minutes: 15);

  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;

  Future<bool> isLocked() async {
    final digest = await _storage.read(key: _digestKey);
    return digest != null && digest.isNotEmpty;
  }

  Future<void> enable(String pin) async {
    final normalized = pin.trim();
    if (normalized.length < 4) {
      throw const AppLockException('pin_too_short');
    }
    // Same rule as `disable`, seen from the other side, and it only matters
    // because of `change()`: this method is reached while an old digest is still
    // on the phone. Writing a new salt over it and then failing to write the
    // digest would leave that old digest behind a salt that cannot reproduce it —
    // the dead end `disable` was reordered away from. Taking the digest off first
    // means every halfway point here leaves a salt nothing reads, so the worst a
    // refusing keystore can cause is a lock that came off. That can be put back
    // on; a lock no PIN opens cannot.
    await _storage.delete(key: _digestKey);
    final salt = _randomSalt();
    await _storage.write(key: _saltKey, value: base64Encode(salt));
    await _storage.write(key: _digestKey, value: _digest(salt, normalized));
  }

  Future<bool> verify(String pin) async {
    final storedSalt = await _storage.read(key: _saltKey);
    final storedDigest = await _storage.read(key: _digestKey);
    if (storedSalt == null || storedDigest == null) return false;
    final List<int> salt;
    try {
      salt = base64Decode(storedSalt);
    } on FormatException {
      // A salt the storage hands back in a shape that cannot be decoded matches
      // no PIN at all, so the honest answer is "no". Throwing here would have
      // reached the unlock screen as an exception instead of an answer, and that
      // screen had no way to recover from one (see its `_submit`).
      return false;
    }
    final candidate = _digest(salt, pin.trim());
    return _constantTimeEquals(candidate, storedDigest);
  }

  /// One try at the PIN, answered with an outcome instead of a bare yes/no.
  ///
  /// A four-digit PIN is ten thousand guesses, and a phone left on a table is
  /// enough time to try them: so wrong answers are counted in the keystore, and
  /// once they pass [failuresBeforeLockout] the gate stops answering at all for
  /// [firstLockout], doubling from there up to [maxLockout]. The count survives
  /// the process, because an app that forgets its failures has no limit at all —
  /// kill it and start again is exactly the attack.
  ///
  /// A correct PIN during a lockout is refused too, deliberately: the check is
  /// not a reward for guessing right, it is what makes guessing expensive. The
  /// cap is what keeps that from becoming a lock nobody can open.
  Future<PinAttempt> attempt(String pin) async {
    final now = _clock();
    final until = await _lockedUntil();
    if (until != null && until.isAfter(now)) {
      return PinAttempt(accepted: false, retryAfter: until.difference(now));
    }

    if (await verify(pin)) {
      await _clearFailures();
      return const PinAttempt(accepted: true);
    }

    final failures = await _failureCount() + 1;
    await _storage.write(key: _failuresKey, value: '$failures');
    if (failures < failuresBeforeLockout) {
      return const PinAttempt(accepted: false);
    }

    final wait = _lockoutFor(failures);
    await _storage.write(
      key: _lockedUntilKey,
      value: '${now.add(wait).millisecondsSinceEpoch}',
    );
    return PinAttempt(accepted: false, retryAfter: wait);
  }

  /// How long the gate is still refusing, or null if it will answer now.
  ///
  /// Read on the gate's first frame as well as on a submit: a phone that was
  /// killed mid-lockout and reopened would otherwise start the count again from
  /// zero, which is the same free retry the count exists to deny.
  Future<Duration?> lockoutRemaining() async {
    final until = await _lockedUntil();
    if (until == null) return null;
    final left = until.difference(_clock());
    return left > Duration.zero ? left : null;
  }

  Future<int> _failureCount() async {
    final raw = await _storage.read(key: _failuresKey);
    return int.tryParse(raw ?? '') ?? 0;
  }

  Future<DateTime?> _lockedUntil() async {
    final raw = await _storage.read(key: _lockedUntilKey);
    final ms = int.tryParse(raw ?? '');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _clearFailures() async {
    await _storage.delete(key: _failuresKey);
    await _storage.delete(key: _lockedUntilKey);
  }

  /// 30s, 60s, 2m, 4m, 8m, then the 15m ceiling.
  static Duration _lockoutFor(int failures) {
    final doublings = failures - failuresBeforeLockout;
    final seconds = firstLockout.inSeconds * (1 << doublings);
    return seconds >= maxLockout.inSeconds
        ? maxLockout
        : Duration(seconds: seconds);
  }

  Future<void> change(String currentPin, String newPin) async {
    final answer = await attempt(currentPin);
    if (!answer.accepted) {
      throw AppLockException(
        answer.retryAfter == null ? 'wrong_pin' : 'locked_out',
      );
    }
    await enable(newPin);
  }

  /// Removing the lock, in the one order a half-finished call can survive.
  ///
  /// The digest is the keyhole: `isLocked()` reads it alone, and `verify()` can
  /// only ever answer no once the salt is gone. So a delete that stops after the
  /// first key leaves an undecodable lock — the unlock screen opens, no PIN ever
  /// matches, and the only way back into the records is a restore. Deleting the
  /// digest first leaves the opposite residue, a salt nothing reads, and the app
  /// simply opens unlocked.
  Future<void> disable() async {
    await _storage.delete(key: _digestKey);
    await _storage.delete(key: _saltKey);
  }

  static List<int> _randomSalt() {
    final rand = Random.secure();
    return List<int>.generate(16, (_) => rand.nextInt(256), growable: false);
  }

  static String _digest(List<int> salt, String pin) =>
      sha256.convert(<int>[...salt, ...utf8.encode(pin)]).toString();

  /// Length-checked then byte-compared without early exit, so a wrong PIN cannot
  /// be probed one character at a time through timing differences.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}

class AppLockException implements Exception {
  const AppLockException(this.reason);
  final String reason;
}

/// The answer to one PIN try: whether it opened the gate, and — when it did not
/// — how long the gate will keep refusing. `retryAfter` is null for an ordinary
/// wrong PIN, which is still an answer the field can be tried again after.
class PinAttempt {
  const PinAttempt({required this.accepted, this.retryAfter});

  final bool accepted;
  final Duration? retryAfter;
}

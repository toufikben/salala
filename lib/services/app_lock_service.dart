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
  AppLockService({FlutterSecureStorage? storage})
    : _storage = storage ?? _defaultStorage;

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

  final FlutterSecureStorage _storage;

  Future<bool> isLocked() async {
    final digest = await _storage.read(key: _digestKey);
    return digest != null && digest.isNotEmpty;
  }

  Future<void> enable(String pin) async {
    final normalized = pin.trim();
    if (normalized.length < 4) {
      throw const AppLockException('pin_too_short');
    }
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

  Future<void> change(String currentPin, String newPin) async {
    if (!await verify(currentPin)) {
      throw const AppLockException('wrong_pin');
    }
    await enable(newPin);
  }

  Future<void> disable() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _digestKey);
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

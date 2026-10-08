import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// In-memory stand-in for the platform keystore, so the PIN logic is testable
/// without a device.
class FakeSecureStorage extends FlutterSecureStorage {
  FakeSecureStorage() : super();

  final Map<String, String> values = <String, String>{};

  /// Keys a write of this key must fail, named so a test can hand the app a real
  /// half-finished keystore call. The keystore does refuse on a device — a
  /// locked keychain, an Android `UnrecoverableEntryNotFoundException` — and
  /// which key survives is the whole difference between an app that opens
  /// unlocked and one that can never be unlocked again.
  final Set<String> writeRefused = <String>{};
  final Set<String> deleteRefused = <String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (writeRefused.contains(key)) {
      throw StateError('the keystore refused to write $key');
    }
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (deleteRefused.contains(key)) {
      throw StateError('the keystore refused to delete $key');
    }
    values.remove(key);
  }
}

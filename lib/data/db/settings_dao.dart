import 'package:sqflite/sqflite.dart';

/// Key/value preferences that are not secret (locale, currency, lock timeout).
/// The PIN digest deliberately does *not* live here — see AppLockService.
class SettingsDao {
  SettingsDao(this.db);

  final Database db;

  Future<String?> read(String key) async {
    final rows = await db.query(
      'user_settings',
      columns: <String>['value'],
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> write(String key, String value, {int? nowMs}) =>
      db.insert('user_settings', <String, Object?>{
        'key': key,
        'value': value,
        'updated_at': nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> remove(String key) =>
      db.delete('user_settings', where: 'key = ?', whereArgs: <Object?>[key]);

  Future<int?> readInt(String key) async {
    final raw = await read(key);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<bool> readBool(String key) async => (await read(key)) == '1';

  Future<void> writeBool(String key, bool value, {int? nowMs}) =>
      write(key, value ? '1' : '0', nowMs: nowMs);
}

class SettingKeys {
  SettingKeys._();

  static const String appLockEnabled = 'app_lock_enabled';
  static const String lockTimeoutSeconds = 'lock_timeout_seconds';
  static const String preferredCurrency = 'preferred_currency';
  static const String defaultSpecies = 'default_species';
  static const String languageCode = 'language_code';
}

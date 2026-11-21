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

  /// The four settings that are deliberately *not* keys here.
  ///
  /// `app_lock_enabled` and `lock_timeout_seconds` were constants in this class
  /// and nothing ever wrote or read them: the lock is real when a digest exists
  /// in the keystore, and the grace period is `lockGracePeriodProvider`. A
  /// constant that says otherwise is a second source of truth that is always
  /// wrong, and a pack restored onto a new phone would have carried it.
  ///
  /// `preferred_currency` went the same way once every placement carried its own
  /// money: the currency is a property of the sale, not of the breeder, and
  /// summing across currencies is the bug the statistics screen refuses. A
  /// default here would have quietly offered to convert what must not be
  /// converted.
  ///
  /// `default_species` never had a field to fill it. The form opens on `dog`.
  static const String languageCode = 'language_code';

  /// When a pack last left this phone, in unix milliseconds.
  ///
  /// Kept beside the export button rather than in the pack itself: the question
  /// it answers — "how old is the only copy of this ledger" — is about this
  /// device's habit, and a restored pack must not claim the new phone has been
  /// backing up. `_importPack` clears it for exactly that reason.
  static const String lastPackExportedAt = 'last_pack_exported_at';

  /// Whether the three introductory slides have been seen.
  ///
  /// A row rather than a `shared_preferences` first-run flag, for the same reason
  /// `lastPackExportedAt` is one: it is a setting of this device, it can be
  /// cleared by a restore of someone else's pack, and Settings offers a row that
  /// shows the slides again — which is a thing no first-run flag can do.
  static const String onboardingSeen = 'onboarding_seen';

  /// The day the free trial began, in unix milliseconds, written once at the
  /// first launch and never moved.
  ///
  /// In the settings table rather than the keystore on purpose: a keystore a
  /// restore could not carry would look like a fresh install, and a breeder who
  /// brought her ledger to a new phone would be handed a second trial for it.
  static const String trialStartedAt = 'trial_started_at';
}

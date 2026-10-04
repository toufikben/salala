import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

import 'schema.dart';

/// Opens the local SQLite database and upgrades it to [schemaVersion].
///
/// Phase 0-2 ships without SQLCipher on purpose: an app-lock PIN gives the
/// practical protection breeders ask for, while keeping the database testable
/// on desktop (`sqflite_common_ffi`) and free of key-loss lock-out risk.
/// `encryptionCipher` stays as the seam for a later opt-in encryption step.
class AppDatabase {
  AppDatabase._();

  static Future<Database> openAt(String path, {int? version}) async {
    return openDatabase(
      path,
      version: version ?? schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Tests open several in-memory databases in one process; SQLite treats any
  /// path beginning with `:memory:` as private, so a suffix keeps them isolated.
  static Future<Database> openInMemory({String name = ''}) async {
    return openDatabase(
      '$inMemoryDatabasePath$name',
      version: schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onCreate(Database db, int version) async {
    for (final statement in createStatements) {
      await db.execute(statement);
    }
  }

  /// Migrations are listed by the version they produce. v1 has no predecessors;
  /// append future steps here instead of editing [createStatements], otherwise
  /// existing installs silently skip new columns.
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) =>
      runMigrations(db, oldVersion, newVersion);

  /// Public so tests can drive an upgrade without a real on-disk database.
  static Future<void> runMigrations(Database db, int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      final step = _migrations[v];
      if (step == null) {
        throw StateError('No migration registered for schema version $v');
      }
      await step(db);
    }
  }

  static final Map<int, Future<void> Function(Database db)> _migrations =
      <int, Future<void> Function(Database db)>{};

  /// Production migrations belong in [_migrations] as a literal; this hook only
  /// exists so tests can prove the runner steps forward exactly once per version.
  @visibleForTesting
  static void registerMigration(
    int version,
    Future<void> Function(Database db) step,
  ) => _migrations[version] = step;

  @visibleForTesting
  static void resetMigrationsForTest() => _migrations.clear();
}

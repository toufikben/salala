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
  /// append future steps to [_productionMigrations] instead of editing
  /// [createStatements] alone, otherwise existing installs silently skip new
  /// tables and columns — an install created before version 2 has no `symptoms`
  /// to insert into.
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

  /// The live registry: the shipped steps plus anything a test registers over
  /// it. Kept separate from [_productionMigrations] so a test can add a scratch
  /// version and hand it back without erasing a real migration.
  static final Map<int, Future<void> Function(Database db)> _migrations =
      Map.of(_productionMigrations);

  /// Version 2 adds the `symptoms` table. It runs the very [createSymptomsTable]
  /// text a fresh install runs, so an upgraded phone and a brand-new one end up
  /// holding one shape of row rather than two.
  static const Map<int, Future<void> Function(Database db)>
  _productionMigrations = <int, Future<void> Function(Database db)>{
    2: AppDatabase._addSymptoms,
  };

  static Future<void> _addSymptoms(Database db) async {
    await db.execute(createSymptomsTable);
    await db.execute(createSymptomsIndex);
  }

  /// Production migrations belong in [_productionMigrations] as a literal; this
  /// hook only exists so tests can prove the runner steps forward exactly once
  /// per version.
  @visibleForTesting
  static void registerMigration(
    int version,
    Future<void> Function(Database db) step,
  ) => _migrations[version] = step;

  /// Restores the shipped steps rather than emptying the map, because a test
  /// that cleared it would hand the rest of the file a database with no real
  /// migrations in it.
  @visibleForTesting
  static void resetMigrationsForTest() {
    _migrations
      ..clear()
      ..addAll(_productionMigrations);
  }
}

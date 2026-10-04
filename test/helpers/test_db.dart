import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:salala/data/db/app_database.dart';

bool _factoryInstalled = false;

/// Runs the real Android SQL stack on the desktop test VM.
///
/// Each call gets its own temporary database file: SQLite only treats the exact
/// string `:memory:` as in-memory, and sqflite_common_ffi shares one connection
/// per path, so a file per test is what keeps counts and cascades isolated.
Future<Database> openTestDatabase() async {
  if (!_factoryInstalled) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _factoryInstalled = true;
  }

  final dir = await Directory.systemTemp.createTemp('salala_test_');
  final db = await AppDatabase.openAt(
    '${dir.path}${Platform.pathSeparator}salala.db',
  );
  addTearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });
  return db;
}

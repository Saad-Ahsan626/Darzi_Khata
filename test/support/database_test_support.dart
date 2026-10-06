import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/error/failures.dart';

/// Points sqflite at the desktop SQLite library. Call from setUpAll.
void useDesktopDatabases() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// A path for a database file that is removed when the test ends.
String temporaryDatabasePath() {
  final directory = Directory.systemTemp.createTempSync('tailor_khata_test_');
  addTearDown(() => directory.deleteSync(recursive: true));
  return p.join(directory.path, 'test.db');
}

/// Opens the database at [path], or a new empty one, at the current schema
/// version. It is closed when the test ends.
Future<DatabaseHelper> openTestDatabase([String? path]) async {
  final helper = DatabaseHelper.atPath(path ?? temporaryDatabasePath());
  addTearDown(helper.close);
  await helper.database;
  return helper;
}

T valueOf<T>(Either<Failure, T> result) =>
    result.fold((failure) => fail(failure.message), (value) => value);

Failure failureOf(Either<Failure, Object?> result) =>
    result.fold((failure) => failure, (_) => fail('Expected a failure'));

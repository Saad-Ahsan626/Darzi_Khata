import 'dart:async';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tailor_khata/core/database/database_migrations.dart';
import 'package:tailor_khata/core/database/database_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  /// The app's database file, kept under its original name.
  static const fileName = 'tailor_khata.db';

  final String? _path;
  Database? _database;

  /// Set while [whileClosed] has the file; reads wait for it.
  Completer<void>? _closedFor;

  DatabaseHelper._init([this._path]);

  /// A helper for the database file at [path], used by tests to work on an
  /// isolated database instead of the app's own.
  factory DatabaseHelper.atPath(String path) => DatabaseHelper._init(path);

  Future<Database> get database async {
    await _untilReopened();
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<void> _untilReopened() async {
    for (var closed = _closedFor; closed != null; closed = _closedFor) {
      await closed.future;
    }
  }

  /// Where the database file is.
  Future<String> get filePath async =>
      _path ?? join(await getDatabasesPath(), fileName);

  /// Closes the database while [action] works on its file, such as copying
  /// it or replacing it, then opens it again, upgrading it if needed.
  /// Anything that asks for the database meanwhile waits.
  Future<void> whileClosed(Future<void> Function(String path) action) async {
    // Taken before the first await, so a read asked for right after this
    // call already waits. An earlier holder finishes first.
    final earlier = _closedFor;
    final closed = _closedFor = Completer<void>();
    try {
      if (earlier != null) await earlier.future;
      await _database?.close();
      _database = null;
      await action(await filePath);
      _database = await _initDB();
    } finally {
      if (identical(_closedFor, closed)) _closedFor = null;
      closed.complete();
    }
  }

  Future<Database> _initDB() async {
    return await openDatabase(
      await filePath,
      version: DatabaseSchema.version,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    for (final statement in DatabaseSchema.createStatements) {
      await db.execute(statement);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE ${DatabaseSchema.customersTable} ADD COLUMN urduName TEXT;");
      await db.execute("ALTER TABLE ${DatabaseSchema.customersTable} ADD COLUMN address TEXT;");
      await db.execute("ALTER TABLE ${DatabaseSchema.customersTable} ADD COLUMN imagePath TEXT;");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE ${DatabaseSchema.ordersTable} ADD COLUMN deliveredAt INTEGER;");
    }
    if (oldVersion < 4) {
      await DatabaseMigrations.toV4(db);
    }
    if (oldVersion < 5) {
      await DatabaseMigrations.toV5(db);
    }
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tailor_khata/core/database/database_migrations.dart';
import 'package:tailor_khata/core/database/database_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  final String? _path;
  Database? _database;

  DatabaseHelper._init([this._path]);

  /// A helper for the database file at [path], used by tests to work on an
  /// isolated database instead of the app's own.
  factory DatabaseHelper.atPath(String path) => DatabaseHelper._init(path);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tailor_khata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final path = _path ?? join(await getDatabasesPath(), filePath);

    return await openDatabase(
      path,
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
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

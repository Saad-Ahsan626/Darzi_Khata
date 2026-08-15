import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:tailor_khata/core/database/database_schema.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tailor_khata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute(DatabaseSchema.createCustomersTable);
    await db.execute(DatabaseSchema.createMeasurementsTable);
    await db.execute(DatabaseSchema.createOrdersTable);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}


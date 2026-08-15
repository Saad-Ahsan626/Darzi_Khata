import 'package:sqflite/sqflite.dart';
import 'package:tailor_khata/core/database/database_helper.dart';
import 'package:tailor_khata/core/database/database_schema.dart';
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/features/measurements/data/models/measurement_model.dart';

abstract class MeasurementLocalDataSource {
  Future<List<MeasurementModel>> getMeasurements();
  Future<List<MeasurementModel>> getMeasurementsByCustomer(String customerId);
  Future<MeasurementModel> getMeasurementById(String id);
  Future<void> saveMeasurement(MeasurementModel measurement);
  Future<void> addMeasurement(MeasurementModel measurement);
  Future<void> updateMeasurement(MeasurementModel measurement);
  Future<void> deleteMeasurement(String id);
}

class MeasurementLocalDataSourceImpl implements MeasurementLocalDataSource {
  final DatabaseHelper dbHelper;

  MeasurementLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<MeasurementModel>> getMeasurements() async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(DatabaseSchema.measurementsTable, orderBy: 'createdAt DESC');
      return result.map((json) => MeasurementModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch measurements: $e');
    }
  }

  @override
  Future<List<MeasurementModel>> getMeasurementsByCustomer(String customerId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.measurementsTable,
        where: 'customerId = ?',
        whereArgs: [customerId],
        orderBy: 'createdAt DESC'
      );
      return result.map((json) => MeasurementModel.fromJson(json)).toList();
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch measurements by customer: $e');
    }
  }

  @override
  Future<MeasurementModel> getMeasurementById(String id) async {
    try {
      final db = await dbHelper.database;
      final result = await db.query(
        DatabaseSchema.measurementsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result.isNotEmpty) {
        return MeasurementModel.fromJson(result.first);
      } else {
        throw LocalDatabaseException('Measurement not found');
      }
    } catch (e) {
      throw LocalDatabaseException('Failed to fetch measurement: $e');
    }
  }

  @override
  Future<void> saveMeasurement(MeasurementModel measurement) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        DatabaseSchema.measurementsTable,
        measurement.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to save measurement: $e');
    }
  }

  @override
  Future<void> addMeasurement(MeasurementModel measurement) => saveMeasurement(measurement);

  @override
  Future<void> updateMeasurement(MeasurementModel measurement) => saveMeasurement(measurement);

  @override
  Future<void> deleteMeasurement(String id) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        DatabaseSchema.measurementsTable,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException('Failed to delete measurement: $e');
    }
  }
}

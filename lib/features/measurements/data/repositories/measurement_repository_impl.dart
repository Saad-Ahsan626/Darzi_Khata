import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/measurements/data/datasources/measurement_local_data_source.dart';
import 'package:tailor_khata/features/measurements/data/models/measurement_model.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/repositories/measurement_repository.dart';

class MeasurementRepositoryImpl implements MeasurementRepository {
  final MeasurementLocalDataSource localDataSource;

  MeasurementRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Measurement>>> getMeasurementsByCustomer(String customerId) async {
    try {
      final models = await localDataSource.getMeasurementsByCustomer(customerId);
      return Right(models);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Measurement>> getMeasurementById(String id) async {
    try {
      final model = await localDataSource.getMeasurementById(id);
      return Right(model);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addMeasurement(Measurement measurement) async {
    try {
      final model = MeasurementModel.fromEntity(measurement);
      await localDataSource.addMeasurement(model);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateMeasurement(Measurement measurement) async {
    try {
      final model = MeasurementModel.fromEntity(measurement);
      await localDataSource.updateMeasurement(model);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMeasurement(String id) async {
    try {
      await localDataSource.deleteMeasurement(id);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}

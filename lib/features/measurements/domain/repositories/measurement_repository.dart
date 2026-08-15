import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';

abstract class MeasurementRepository {
  Future<Either<Failure, List<Measurement>>> getMeasurementsByCustomer(String customerId);
  Future<Either<Failure, Measurement>> getMeasurementById(String id);
  Future<Either<Failure, void>> addMeasurement(Measurement measurement);
  Future<Either<Failure, void>> updateMeasurement(Measurement measurement);
  Future<Either<Failure, void>> deleteMeasurement(String id);
}

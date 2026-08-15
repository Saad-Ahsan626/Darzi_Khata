import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/repositories/measurement_repository.dart';

class GetMeasurementsByCustomer implements UseCase<List<Measurement>, String> {
  final MeasurementRepository repository;

  GetMeasurementsByCustomer(this.repository);

  @override
  Future<Either<Failure, List<Measurement>>> call(String params) async {
    return await repository.getMeasurementsByCustomer(params);
  }
}

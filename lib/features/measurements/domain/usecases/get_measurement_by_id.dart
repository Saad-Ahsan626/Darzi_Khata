import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/repositories/measurement_repository.dart';

class GetMeasurementById implements UseCase<Measurement, String> {
  final MeasurementRepository repository;

  GetMeasurementById(this.repository);

  @override
  Future<Either<Failure, Measurement>> call(String params) async {
    return await repository.getMeasurementById(params);
  }
}

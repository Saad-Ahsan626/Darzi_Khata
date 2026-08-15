import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/repositories/measurement_repository.dart';

class UpdateMeasurement implements UseCase<void, Measurement> {
  final MeasurementRepository repository;

  UpdateMeasurement(this.repository);

  @override
  Future<Either<Failure, void>> call(Measurement params) async {
    return await repository.updateMeasurement(params);
  }
}

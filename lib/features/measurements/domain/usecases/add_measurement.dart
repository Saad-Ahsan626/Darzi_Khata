import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/domain/repositories/measurement_repository.dart';

class AddMeasurement implements UseCase<void, Measurement> {
  final MeasurementRepository repository;

  AddMeasurement(this.repository);

  @override
  Future<Either<Failure, void>> call(Measurement params) async {
    return await repository.addMeasurement(params);
  }
}

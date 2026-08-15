import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/measurements/domain/repositories/measurement_repository.dart';

class DeleteMeasurement implements UseCase<void, String> {
  final MeasurementRepository repository;

  DeleteMeasurement(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteMeasurement(params);
  }
}

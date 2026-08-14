import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';

abstract class UseCase<OutputType, Params> {
  Future<Either<Failure, OutputType>> call(Params params);
}

class NoParams {
  const NoParams();
}

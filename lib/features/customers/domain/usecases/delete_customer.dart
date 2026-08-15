import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/customers/domain/repositories/customer_repository.dart';

class DeleteCustomer implements UseCase<void, String> {
  final CustomerRepository repository;

  DeleteCustomer(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteCustomer(params);
  }
}

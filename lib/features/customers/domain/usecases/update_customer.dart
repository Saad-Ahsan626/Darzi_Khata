import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/repositories/customer_repository.dart';

class UpdateCustomer implements UseCase<void, Customer> {
  final CustomerRepository repository;

  UpdateCustomer(this.repository);

  @override
  Future<Either<Failure, void>> call(Customer params) async {
    return await repository.updateCustomer(params);
  }
}

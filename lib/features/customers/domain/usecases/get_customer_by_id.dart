import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/repositories/customer_repository.dart';

class GetCustomerById implements UseCase<Customer, String> {
  final CustomerRepository repository;

  GetCustomerById(this.repository);

  @override
  Future<Either<Failure, Customer>> call(String params) async {
    return await repository.getCustomerById(params);
  }
}

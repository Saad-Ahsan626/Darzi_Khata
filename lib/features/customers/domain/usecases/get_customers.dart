import 'package:fpdart/fpdart.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/repositories/customer_repository.dart';

class GetCustomers implements UseCase<List<Customer>, NoParams> {
  final CustomerRepository repository;

  GetCustomers(this.repository);

  @override
  Future<Either<Failure, List<Customer>>> call(NoParams params) async {
    return await repository.getCustomers();
  }
}

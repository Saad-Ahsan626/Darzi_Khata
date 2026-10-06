import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class GetPayments implements UseCase<List<Payment>, NoParams> {
  final OrderRepository repository;

  GetPayments(this.repository);

  @override
  Future<Either<Failure, List<Payment>>> call(NoParams params) async {
    return await repository.getPayments();
  }
}

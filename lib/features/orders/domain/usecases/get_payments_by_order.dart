import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class GetPaymentsByOrder implements UseCase<List<Payment>, String> {
  final OrderRepository repository;

  GetPaymentsByOrder(this.repository);

  @override
  Future<Either<Failure, List<Payment>>> call(String params) async {
    return await repository.getPaymentsByOrder(params);
  }
}

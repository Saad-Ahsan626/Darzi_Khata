import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class GetOrdersByCustomer implements UseCase<List<Order>, String> {
  final OrderRepository repository;

  GetOrdersByCustomer(this.repository);

  @override
  Future<Either<Failure, List<Order>>> call(String params) async {
    return await repository.getOrdersByCustomer(params);
  }
}

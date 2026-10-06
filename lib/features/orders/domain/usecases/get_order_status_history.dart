import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class GetOrderStatusHistory implements UseCase<List<OrderStatusEvent>, String> {
  final OrderRepository repository;

  GetOrderStatusHistory(this.repository);

  @override
  Future<Either<Failure, List<OrderStatusEvent>>> call(String params) async {
    return await repository.getStatusHistory(params);
  }
}

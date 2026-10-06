import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class ChangeOrderStatusParams {
  final String orderId;
  final String status;
  final DateTime changedAt;

  const ChangeOrderStatusParams({
    required this.orderId,
    required this.status,
    required this.changedAt,
  });
}

/// Moves an order to another production stage. Payments are not affected.
class ChangeOrderStatus implements UseCase<void, ChangeOrderStatusParams> {
  final OrderRepository repository;

  ChangeOrderStatus(this.repository);

  @override
  Future<Either<Failure, void>> call(ChangeOrderStatusParams params) async {
    if (!OrderStatus.production.contains(params.status)) {
      return Left(
        ValidationFailure('${params.status} is not a production stage'),
      );
    }
    final found = await repository.getOrderById(params.orderId);
    return found.fold<Future<Either<Failure, void>>>(
      (failure) async => Left(failure),
      (order) async {
        if (order.status == OrderStatus.delivered) {
          return const Left(
            ValidationFailure('A delivered order cannot change status'),
          );
        }
        if (order.status == params.status) return const Right(null);
        return repository.changeStatus(
          orderId: params.orderId,
          status: params.status,
          changedAt: params.changedAt,
        );
      },
    );
  }
}

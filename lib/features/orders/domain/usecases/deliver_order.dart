import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class DeliverOrderParams {
  final String orderId;
  final DateTime deliveredAt;

  /// Record the remaining balance as paid before delivering.
  final bool settleBalance;
  final PaymentMethod method;

  const DeliverOrderParams({
    required this.orderId,
    required this.deliveredAt,
    this.settleBalance = false,
    this.method = PaymentMethod.cash,
  });
}

/// Marks an order delivered. The balance stays owed unless
/// [DeliverOrderParams.settleBalance] records it as a payment first.
class DeliverOrder implements UseCase<void, DeliverOrderParams> {
  final OrderRepository repository;

  DeliverOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(DeliverOrderParams params) async {
    final found = await repository.getOrderById(params.orderId);
    return found.fold<Future<Either<Failure, void>>>(
      (failure) async => Left(failure),
      (order) async {
        if (order.status == OrderStatus.delivered) {
          return const Left(
            ValidationFailure('This order is already delivered'),
          );
        }
        if (params.settleBalance && order.balance > 0) {
          final paid = await repository.recordPayment(
            orderId: order.id,
            amount: order.balance,
            method: params.method,
            paidAt: params.deliveredAt,
          );
          if (paid case Left(value: final failure)) return Left(failure);
        }
        return repository.deliverOrder(
          orderId: order.id,
          deliveredAt: params.deliveredAt,
        );
      },
    );
  }
}

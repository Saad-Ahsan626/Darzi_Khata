import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class RecordPaymentParams {
  final String orderId;
  final double amount;
  final PaymentMethod method;
  final DateTime paidAt;

  const RecordPaymentParams({
    required this.orderId,
    required this.amount,
    required this.method,
    required this.paidAt,
  });
}

/// Records money received for an order, up to its outstanding balance.
class RecordPayment implements UseCase<Payment, RecordPaymentParams> {
  final OrderRepository repository;

  RecordPayment(this.repository);

  @override
  Future<Either<Failure, Payment>> call(RecordPaymentParams params) async {
    if (params.amount <= 0) {
      return const Left(ValidationFailure('Enter an amount greater than zero'));
    }
    final found = await repository.getOrderById(params.orderId);
    return found.fold<Future<Either<Failure, Payment>>>(
      (failure) async => Left(failure),
      (order) async {
        if (params.amount > order.balance) {
          return const Left(
            ValidationFailure('The amount is more than the outstanding balance'),
          );
        }
        return repository.recordPayment(
          orderId: params.orderId,
          amount: params.amount,
          method: params.method,
          paidAt: params.paidAt,
        );
      },
    );
  }
}

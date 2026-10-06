import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

/// Saves edits to an order's details. The total cannot drop below what the
/// customer has already paid.
class UpdateOrder implements UseCase<void, Order> {
  final OrderRepository repository;

  UpdateOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(Order params) async {
    final found = await repository.getOrderById(params.id);
    return found.fold<Future<Either<Failure, void>>>(
      (failure) async => Left(failure),
      (stored) async {
        if (params.totalAmount < stored.paidAmount) {
          return const Left(
            ValidationFailure(
              'The total cannot be less than the amount already paid',
            ),
          );
        }
        return repository.updateOrder(params);
      },
    );
  }
}

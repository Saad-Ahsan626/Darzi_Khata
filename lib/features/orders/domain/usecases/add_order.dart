import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class AddOrder implements UseCase<void, Order> {
  final OrderRepository repository;

  AddOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(Order params) async {
    return await repository.addOrder(params);
  }
}

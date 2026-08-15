import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class DeleteOrder implements UseCase<void, String> {
  final OrderRepository repository;

  DeleteOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(String params) async {
    return await repository.deleteOrder(params);
  }
}

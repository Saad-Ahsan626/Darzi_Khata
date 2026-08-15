import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<Order>>> getOrders();
  Future<Either<Failure, Order>> getOrderById(String id);
  Future<Either<Failure, List<Order>>> getOrdersByCustomer(String customerId);
  Future<Either<Failure, void>> addOrder(Order order);
  Future<Either<Failure, void>> updateOrder(Order order);
  Future<Either<Failure, void>> deleteOrder(String id);
}

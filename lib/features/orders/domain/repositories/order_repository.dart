import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<Order>>> getOrders();
  Future<Either<Failure, Order>> getOrderById(String id);
  Future<Either<Failure, List<Order>>> getOrdersByCustomer(String customerId);

  /// Saves a new order with the next order number. Its status becomes the
  /// first history entry and a paid amount becomes the advance payment.
  Future<Either<Failure, void>> addOrder(Order order);

  /// Saves the order's details. Status, payments and the order number are
  /// left as stored; they change through their own operations.
  Future<Either<Failure, void>> updateOrder(Order order);
  Future<Either<Failure, void>> deleteOrder(String id);

  Future<Either<Failure, void>> changeStatus({
    required String orderId,
    required String status,
    required DateTime changedAt,
  });
  Future<Either<Failure, void>> deliverOrder({
    required String orderId,
    required DateTime deliveredAt,
  });
  Future<Either<Failure, List<OrderStatusEvent>>> getStatusHistory(
    String orderId,
  );

  Future<Either<Failure, Payment>> recordPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    required DateTime paidAt,
  });
  Future<Either<Failure, void>> deletePayment(String paymentId);

  /// Every payment, newest first.
  Future<Either<Failure, List<Payment>>> getPayments();
  Future<Either<Failure, List<Payment>>> getPaymentsByOrder(String orderId);
}

import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/orders/data/datasources/order_local_data_source.dart';
import 'package:tailor_khata/features/orders/data/models/order_model.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderLocalDataSource localDataSource;

  OrderRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, List<Order>>> getOrders() async {
    try {
      final models = await localDataSource.getOrders();
      return Right(models);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String id) async {
    try {
      final model = await localDataSource.getOrderById(id);
      return Right(model);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Order>>> getOrdersByCustomer(String customerId) async {
    try {
      final models = await localDataSource.getOrdersByCustomer(customerId);
      return Right(models);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addOrder(Order order) async {
    try {
      final model = OrderModel.fromEntity(order);
      await localDataSource.addOrder(model);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrder(Order order) async {
    try {
      final model = OrderModel.fromEntity(order);
      await localDataSource.updateOrder(model);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteOrder(String id) async {
    try {
      await localDataSource.deleteOrder(id);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> changeStatus({
    required String orderId,
    required String status,
    required DateTime changedAt,
  }) async {
    try {
      await localDataSource.changeStatus(
        orderId: orderId,
        status: status,
        changedAt: changedAt,
      );
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deliverOrder({
    required String orderId,
    required DateTime deliveredAt,
  }) async {
    try {
      await localDataSource.deliverOrder(
        orderId: orderId,
        deliveredAt: deliveredAt,
      );
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<OrderStatusEvent>>> getStatusHistory(
    String orderId,
  ) async {
    try {
      final models = await localDataSource.getStatusHistory(orderId);
      return Right(models);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Payment>> recordPayment({
    required String orderId,
    required double amount,
    required PaymentMethod method,
    required DateTime paidAt,
  }) async {
    try {
      final model = await localDataSource.recordPayment(
        orderId: orderId,
        amount: amount,
        method: method,
        paidAt: paidAt,
      );
      return Right(model);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deletePayment(String paymentId) async {
    try {
      await localDataSource.deletePayment(paymentId);
      return const Right(null);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPayments() async {
    try {
      final models = await localDataSource.getPayments();
      return Right(models);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByOrder(
    String orderId,
  ) async {
    try {
      final models = await localDataSource.getPaymentsByOrder(orderId);
      return Right(models);
    } on LocalDatabaseException catch (e) {
      return Left(DatabaseFailure(e.message));
    }
  }
}

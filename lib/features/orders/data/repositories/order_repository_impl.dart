import 'package:fpdart/fpdart.dart' hide Order;
import 'package:tailor_khata/core/error/exceptions.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/features/orders/data/datasources/order_local_data_source.dart';
import 'package:tailor_khata/features/orders/data/models/order_model.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
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
}

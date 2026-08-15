import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/providers/database_provider.dart';

import 'package:tailor_khata/features/orders/data/datasources/order_local_data_source.dart';
import 'package:tailor_khata/features/orders/data/repositories/order_repository_impl.dart';
import 'package:tailor_khata/features/orders/domain/repositories/order_repository.dart';
import 'package:tailor_khata/features/orders/domain/usecases/add_order.dart';
import 'package:tailor_khata/features/orders/domain/usecases/delete_order.dart';
import 'package:tailor_khata/features/orders/domain/usecases/get_order_by_id.dart';
import 'package:tailor_khata/features/orders/domain/usecases/get_orders.dart';
import 'package:tailor_khata/features/orders/domain/usecases/get_orders_by_customer.dart';
import 'package:tailor_khata/features/orders/domain/usecases/update_order.dart';

final orderLocalDataSourceProvider = Provider<OrderLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseProvider);
  return OrderLocalDataSourceImpl(dbHelper: dbHelper);
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final localDataSource = ref.watch(orderLocalDataSourceProvider);
  return OrderRepositoryImpl(localDataSource: localDataSource);
});

// 3. Use Case Providers
final getOrdersUsecaseProvider = Provider<GetOrders>((ref) {
  return GetOrders(ref.watch(orderRepositoryProvider));
});

final getOrderByIdUsecaseProvider = Provider<GetOrderById>((ref) {
  return GetOrderById(ref.watch(orderRepositoryProvider));
});

final getOrdersByCustomerUsecaseProvider = Provider<GetOrdersByCustomer>((ref) {
  return GetOrdersByCustomer(ref.watch(orderRepositoryProvider));
});

final addOrderUsecaseProvider = Provider<AddOrder>((ref) {
  return AddOrder(ref.watch(orderRepositoryProvider));
});

final updateOrderUsecaseProvider = Provider<UpdateOrder>((ref) {
  return UpdateOrder(ref.watch(orderRepositoryProvider));
});

final deleteOrderUsecaseProvider = Provider<DeleteOrder>((ref) {
  return DeleteOrder(ref.watch(orderRepositoryProvider));
});


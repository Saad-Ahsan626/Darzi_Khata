import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/presentation/providers/order_providers.dart';

class OrdersNotifier extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    return _fetchOrders();
  }

  Future<List<Order>> _fetchOrders() async {
    final getOrders = ref.watch(getOrdersUsecaseProvider);
    final result = await getOrders(const NoParams());
    return result.fold(
      (failure) => throw Exception(failure.message),
      (orders) => orders,
    );
  }

  Future<void> loadOrders() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOrders());
  }

  Future<void> addOrder(Order order) async {
    final addOrderUsecase = ref.read(addOrderUsecaseProvider);
    final result = await addOrderUsecase(order);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadOrders(),
    );
  }

  Future<void> updateOrder(Order order) async {
    final updateOrderUsecase = ref.read(updateOrderUsecaseProvider);
    final result = await updateOrderUsecase(order);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadOrders(),
    );
  }

  Future<void> deleteOrder(String id) async {
    final deleteOrderUsecase = ref.read(deleteOrderUsecaseProvider);
    final result = await deleteOrderUsecase(id);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadOrders(),
    );
  }
}

final ordersNotifierProvider = AsyncNotifierProvider<OrdersNotifier, List<Order>>(() {
  return OrdersNotifier();
});

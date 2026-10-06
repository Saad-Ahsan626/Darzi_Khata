import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/domain/usecases/change_order_status.dart';
import 'package:tailor_khata/features/orders/domain/usecases/deliver_order.dart';
import 'package:tailor_khata/features/orders/domain/usecases/record_payment.dart';
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

  Future<void> changeStatus(String orderId, String status) async {
    final changeStatusUsecase = ref.read(changeOrderStatusUsecaseProvider);
    final result = await changeStatusUsecase(
      ChangeOrderStatusParams(
        orderId: orderId,
        status: status,
        changedAt: DateTime.now(),
      ),
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadOrders(),
    );
  }

  /// With [settleBalance] the remaining balance is recorded as paid in cash.
  Future<void> deliverOrder(
    String orderId, {
    required bool settleBalance,
  }) async {
    final deliverOrderUsecase = ref.read(deliverOrderUsecaseProvider);
    final result = await deliverOrderUsecase(
      DeliverOrderParams(
        orderId: orderId,
        deliveredAt: DateTime.now(),
        settleBalance: settleBalance,
      ),
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadOrders(),
    );
  }

  Future<void> recordPayment(
    String orderId,
    double amount,
    PaymentMethod method,
  ) async {
    final recordPaymentUsecase = ref.read(recordPaymentUsecaseProvider);
    final result = await recordPaymentUsecase(
      RecordPaymentParams(
        orderId: orderId,
        amount: amount,
        method: method,
        paidAt: DateTime.now(),
      ),
    );
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadOrders(),
    );
  }

  Future<void> deletePayment(String paymentId) async {
    final deletePaymentUsecase = ref.read(deletePaymentUsecaseProvider);
    final result = await deletePaymentUsecase(paymentId);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (_) => loadOrders(),
    );
  }
}

final ordersNotifierProvider = AsyncNotifierProvider<OrdersNotifier, List<Order>>(() {
  return OrdersNotifier();
});

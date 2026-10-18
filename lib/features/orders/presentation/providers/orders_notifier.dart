import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/usecase/usecase.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/domain/usecases/change_order_status.dart';
import 'package:tailor_khata/features/orders/domain/usecases/deliver_order.dart';
import 'package:tailor_khata/features/orders/domain/usecases/record_payment.dart';
import 'package:tailor_khata/features/orders/presentation/providers/order_providers.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

/// Every order, with the writes that change them. Each write returns why it
/// failed, or null once it is stored and the list is up to date.
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

  DateTime get _now => ref.read(clockProvider)();

  /// Reads the list again. The current list stays on screen meanwhile.
  Future<void> loadOrders() async {
    state = await AsyncValue.guard(() => _fetchOrders());
  }

  /// Saves a new order. Its number is assigned as it is stored.
  Future<Failure?> addOrder(Order order) async {
    final addOrderUsecase = ref.read(addOrderUsecaseProvider);
    final failure = await _finish(await addOrderUsecase(order));
    // The next order number moved on.
    if (failure == null) ref.invalidate(shopSettingsProvider);
    return failure;
  }

  Future<Failure?> updateOrder(Order order) async {
    final updateOrderUsecase = ref.read(updateOrderUsecaseProvider);
    return _finish(await updateOrderUsecase(order));
  }

  /// Deletes an order with its payments and status history.
  Future<Failure?> deleteOrder(String id) async {
    final deleteOrderUsecase = ref.read(deleteOrderUsecaseProvider);
    return _finish(await deleteOrderUsecase(id));
  }

  /// Moves an order to another production stage. Payments are not touched.
  Future<Failure?> changeStatus(String orderId, String status) async {
    final changeStatusUsecase = ref.read(changeOrderStatusUsecaseProvider);
    return _finish(
      await changeStatusUsecase(
        ChangeOrderStatusParams(
          orderId: orderId,
          status: status,
          changedAt: _now,
        ),
      ),
    );
  }

  /// Marks an order delivered. Any balance stays owed.
  Future<Failure?> deliverOrder(String orderId) async {
    final deliverOrderUsecase = ref.read(deliverOrderUsecaseProvider);
    return _finish(
      await deliverOrderUsecase(
        DeliverOrderParams(orderId: orderId, deliveredAt: _now),
      ),
    );
  }

  /// Records money received. Resolves to the stored payment, so it can be
  /// undone with [deletePayment].
  Future<Either<Failure, Payment>> recordPayment(
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
        paidAt: _now,
      ),
    );
    if (result.isRight()) await loadOrders();
    return result;
  }

  /// Removes a payment, returning its amount to the order's balance.
  Future<Failure?> deletePayment(String paymentId) async {
    final deletePaymentUsecase = ref.read(deletePaymentUsecaseProvider);
    return _finish(await deletePaymentUsecase(paymentId));
  }

  Future<Failure?> _finish(Either<Failure, void> result) async {
    final failure = result.getLeft().toNullable();
    if (failure == null) await loadOrders();
    return failure;
  }
}

final ordersNotifierProvider =
    AsyncNotifierProvider<OrdersNotifier, List<Order>>(() {
      return OrdersNotifier();
    });

/// When an order entered each stage, oldest first. Read again whenever the
/// orders change.
final orderStatusHistoryProvider = FutureProvider.autoDispose
    .family<List<OrderStatusEvent>, String>((ref, orderId) async {
      ref.watch(ordersNotifierProvider);
      final result = await ref.watch(getOrderStatusHistoryUsecaseProvider)(
        orderId,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (events) => events,
      );
    });

/// The payments recorded for an order, newest first. Read again whenever
/// the orders change.
final orderPaymentsProvider = FutureProvider.autoDispose
    .family<List<Payment>, String>((ref, orderId) async {
      ref.watch(ordersNotifierProvider);
      final result = await ref.watch(getPaymentsByOrderUsecaseProvider)(
        orderId,
      );
      return result.fold(
        (failure) => throw Exception(failure.message),
        (payments) => payments,
      );
    });

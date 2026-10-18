import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_sheets.dart';

/// The stage, payment and delivery steps on an order, shared by the order
/// page and Home. Each asks in a sheet or dialog, saves, then confirms with
/// a toast. A failed save is explained in a snack bar.
class OrderActions {
  OrderActions(this.context, this.ref, {this.onBusy});

  final BuildContext context;
  final WidgetRef ref;

  /// Told when a save starts and when it ends.
  final ValueChanged<bool>? onBusy;

  static final _dateTime = DateFormat('d MMM, h:mm a');

  Future<T> _run<T>(Future<T> Function() write) async {
    onBusy?.call(true);
    try {
      return await write();
    } finally {
      onBusy?.call(false);
    }
  }

  void showFailure(Failure failure) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure is ValidationFailure
              ? failure.message
              : "Couldn't save the change. Please try again.",
        ),
      ),
    );
  }

  static String _balanceText(double balance) =>
      balance > 0 ? 'Balance now ${formatRupees(balance)}' : 'Paid in full';

  /// The order's stage history. The read is held open until it finishes,
  /// since outside the order page nothing else keeps it alive. Without it
  /// the sheet still works, only without dates.
  Future<List<OrderStatusEvent>> _history(String orderId) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final read = container.listen(
      orderStatusHistoryProvider(orderId).future,
      (_, _) {},
    );
    try {
      return await read.read();
    } on Exception {
      return const [];
    } finally {
      read.close();
    }
  }

  Future<void> changeStatus(Order order) async {
    final orders = ref.read(ordersNotifierProvider.notifier);
    final history = await _history(order.id);
    if (!context.mounted) return;
    final status = await showChangeStatusSheet(
      context,
      order: order,
      history: history,
    );
    if (status == null || !context.mounted) return;
    final failure = await _run(() => orders.changeStatus(order.id, status));
    if (failure != null) return showFailure(failure);
    if (!context.mounted) return;
    showAppToast(
      context,
      message: 'Moved to $status',
      detail: order.balance > 0
          ? '${formatRupees(order.balance)} still outstanding'
          : null,
    );
  }

  /// Records a payment and, when [thenDeliver], delivers the order after.
  /// [subtitle] names the order in the sheet, such as `TK-0042 · Faisal`.
  Future<void> recordPayment(
    Order order, {
    required String subtitle,
    bool thenDeliver = false,
  }) async {
    final orders = ref.read(ordersNotifierProvider.notifier);
    final entry = await showRecordPaymentSheet(
      context,
      order: order,
      subtitle: subtitle,
    );
    if (entry == null || !context.mounted) return;
    final result = await _run(
      () => orders.recordPayment(order.id, entry.amount, entry.method),
    );
    if (result.getLeft().toNullable() case final failure?) {
      return showFailure(failure);
    }
    final payment = result.getRight().toNullable()!;
    final balance = order.balance - payment.amount;

    if (thenDeliver) {
      final failure = await _run(() => orders.deliverOrder(order.id));
      if (failure != null) return showFailure(failure);
      if (!context.mounted) return;
      showAppToast(
        context,
        message: 'Order delivered',
        detail:
            'Payment of ${formatRupees(payment.amount)} recorded · '
            '${_balanceText(balance)}',
      );
      return;
    }

    if (!context.mounted) return;
    showAppToast(
      context,
      message: 'Payment of ${formatRupees(payment.amount)} recorded',
      detail: '${_balanceText(balance)} · ${_dateTime.format(payment.paidAt)}',
      actionLabel: 'Undo',
      // Undo stays on screen after the page may have closed, so it holds
      // on to the notifier rather than reading it again.
      onAction: () => _undoPayment(orders, payment, order.balance),
    );
  }

  Future<void> _undoPayment(
    OrdersNotifier orders,
    Payment payment,
    double balanceBefore,
  ) async {
    final failure = await orders.deletePayment(payment.id);
    if (failure != null) return showFailure(failure);
    if (!context.mounted) return;
    showAppToast(
      context,
      message: 'Payment removed',
      detail: 'Balance back to ${formatRupees(balanceBefore)}',
    );
  }

  /// Confirms delivery, offering to record a payment first while money is
  /// still owed.
  Future<void> deliver(
    Order order, {
    required String customerName,
    required String subtitle,
  }) async {
    final orders = ref.read(ordersNotifierProvider.notifier);
    final choice = await showDeliverDialog(
      context,
      order: order,
      customerName: customerName,
    );
    if (!context.mounted) return;
    switch (choice) {
      case null:
        return;
      case DeliveryChoice.recordPaymentFirst:
        return recordPayment(order, subtitle: subtitle, thenDeliver: true);
      case DeliveryChoice.deliver:
        final failure = await _run(() => orders.deliverOrder(order.id));
        if (failure != null) return showFailure(failure);
        if (!context.mounted) return;
        showAppToast(
          context,
          message: 'Order delivered',
          detail: order.balance > 0
              ? '${formatRupees(order.balance)} stays outstanding'
              : 'Paid in full',
        );
    }
  }
}

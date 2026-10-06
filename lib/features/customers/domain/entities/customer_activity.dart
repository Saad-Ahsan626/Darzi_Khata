import 'package:equatable/equatable.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';

/// What a customer's orders and saved measurements add up to on a given day.
class CustomerActivity extends Equatable {
  final int orderCount;

  /// Orders not yet delivered.
  final int openOrderCount;

  /// Unpaid balance across all orders, delivered or not.
  final double outstanding;
  final int measurementProfileCount;
  final DateTime? lastOrderDate;

  /// Days the most overdue open order is past its delivery date, or 0.
  final int overdueDays;

  /// Whether an open order is due on the day this was worked out.
  final bool deliveryToday;

  const CustomerActivity({
    this.orderCount = 0,
    this.openOrderCount = 0,
    this.outstanding = 0,
    this.measurementProfileCount = 0,
    this.lastOrderDate,
    this.overdueDays = 0,
    this.deliveryToday = false,
  });

  /// Whether the customer has work in the shop or money owed.
  bool get isActive => openOrderCount > 0 || outstanding > 0;

  /// The activity of every customer who has an order or a measurement
  /// profile, by customer id. Customers with neither are left out.
  static Map<String, CustomerActivity> byCustomer({
    required Iterable<Order> orders,
    required Iterable<Measurement> measurements,
    required DateTime today,
  }) {
    final ordersByCustomer = <String, List<Order>>{};
    for (final order in orders) {
      (ordersByCustomer[order.customerId] ??= []).add(order);
    }
    final profilesByCustomer = <String, int>{};
    for (final measurement in measurements) {
      profilesByCustomer.update(
        measurement.customerId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return {
      for (final id in {...ordersByCustomer.keys, ...profilesByCustomer.keys})
        id: CustomerActivity._from(
          ordersByCustomer[id] ?? const [],
          profilesByCustomer[id] ?? 0,
          today,
        ),
    };
  }

  factory CustomerActivity._from(
    List<Order> orders,
    int measurementProfileCount,
    DateTime today,
  ) {
    var openOrderCount = 0;
    var outstanding = 0.0;
    var overdueDays = 0;
    var deliveryToday = false;
    DateTime? lastOrderDate;
    for (final order in orders) {
      outstanding += order.balance;
      if (lastOrderDate == null || order.createdAt.isAfter(lastOrderDate)) {
        lastOrderDate = order.createdAt;
      }
      if (order.status == OrderStatus.delivered) continue;
      openOrderCount++;
      final daysLate = _daysBetween(order.deliveryDate, today);
      if (daysLate == 0) deliveryToday = true;
      if (daysLate > overdueDays) overdueDays = daysLate;
    }
    return CustomerActivity(
      orderCount: orders.length,
      openOrderCount: openOrderCount,
      outstanding: outstanding,
      measurementProfileCount: measurementProfileCount,
      lastOrderDate: lastOrderDate,
      overdueDays: overdueDays,
      deliveryToday: deliveryToday,
    );
  }

  /// Whole calendar days from [from] to [to], ignoring the time of day.
  static int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  @override
  List<Object?> get props => [
        orderCount,
        openOrderCount,
        outstanding,
        measurementProfileCount,
        lastOrderDate,
        overdueDays,
        deliveryToday,
      ];
}

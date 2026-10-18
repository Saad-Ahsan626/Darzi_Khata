import 'package:equatable/equatable.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';

/// A run of whole days, from [start] up to but not including [end].
class Period extends Equatable {
  final DateTime start;
  final DateTime end;

  const Period._(this.start, this.end);

  /// The days from [first] to [last], both included.
  factory Period.days(DateTime first, DateTime last) => Period._(
    DateTime(first.year, first.month, first.day),
    DateTime(last.year, last.month, last.day + 1),
  );

  factory Period.month(int year, int month) =>
      Period._(DateTime(year, month), DateTime(year, month + 1));

  /// The first of [today]'s month up to and including [today].
  factory Period.monthToDate(DateTime today) =>
      Period.days(DateTime(today.year, today.month), today);

  /// The first of January up to and including [today].
  factory Period.yearToDate(DateTime today) =>
      Period.days(DateTime(today.year), today);

  /// The last day included.
  DateTime get last => DateTime(end.year, end.month, end.day - 1);

  bool contains(DateTime time) => !time.isBefore(start) && time.isBefore(end);

  /// Whether any day of [month] (the first of a month) falls in this period.
  bool overlapsMonth(DateTime month) =>
      DateTime(month.year, month.month + 1).isAfter(start) &&
      month.isBefore(end);

  @override
  List<Object?> get props => [start, end];
}

/// The shop's money over a period. Billing counts orders by the day they
/// were taken; collection counts payments by the day they were received.
class MoneySummary extends Equatable {
  /// The totals of orders taken in the period.
  final double billed;

  /// Payments received in the period, for any order.
  final double collected;

  /// What is still owed on the orders taken in the period.
  final double outstanding;

  /// Orders taken in the period.
  final int orderCount;

  const MoneySummary({
    this.billed = 0,
    this.collected = 0,
    this.outstanding = 0,
    this.orderCount = 0,
  });

  factory MoneySummary.of(
    Period period,
    List<Order> orders,
    List<Payment> payments,
  ) {
    var billed = 0.0;
    var outstanding = 0.0;
    var count = 0;
    for (final order in orders) {
      if (!period.contains(order.createdAt)) continue;
      billed += order.totalAmount;
      outstanding += order.balance;
      count++;
    }
    var collected = 0.0;
    for (final payment in payments) {
      if (period.contains(payment.paidAt)) collected += payment.amount;
    }
    return MoneySummary(
      billed: billed,
      collected: collected,
      outstanding: outstanding,
      orderCount: count,
    );
  }

  /// Collected as a share of billed, or null when nothing was billed.
  double? get collectedShare => billed > 0 ? collected / billed : null;

  @override
  List<Object?> get props => [billed, collected, outstanding, orderCount];
}

/// Money collected in one month.
class MonthTotal extends Equatable {
  /// The first of the month.
  final DateTime month;
  final double amount;

  const MonthTotal(this.month, this.amount);

  @override
  List<Object?> get props => [month, amount];
}

/// What was collected in each of the [count] months ending with [last]'s
/// month, oldest first.
List<MonthTotal> collectedByMonth(
  List<Payment> payments, {
  required DateTime last,
  int count = 6,
}) {
  final months = [
    for (var back = count - 1; back >= 0; back--)
      DateTime(last.year, last.month - back),
  ];
  final totals = {for (final month in months) month: 0.0};
  for (final payment in payments) {
    final month = DateTime(payment.paidAt.year, payment.paidAt.month);
    if (totals.containsKey(month)) {
      totals[month] = totals[month]! + payment.amount;
    }
  }
  return [for (final month in months) MonthTotal(month, totals[month]!)];
}

/// Everything still owed now, and on how many orders.
({double amount, int orders}) totalOutstanding(List<Order> orders) {
  var amount = 0.0;
  var count = 0;
  for (final order in orders) {
    if (order.balance <= 0) continue;
    amount += order.balance;
    count++;
  }
  return (amount: amount, orders: count);
}

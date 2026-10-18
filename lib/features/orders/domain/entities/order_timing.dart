import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';

/// How an order stands against its delivery date.
extension OrderTiming on Order {
  bool get isDelivered => status == OrderStatus.delivered;

  /// Whole days past the delivery date on [today]; negative while it is
  /// still ahead.
  int daysLate(DateTime today) =>
      _day(today).difference(_day(deliveryDate)).inDays;

  /// Not delivered and past its delivery date.
  bool isOverdue(DateTime today) => !isDelivered && daysLate(today) > 0;

  /// Not delivered and due on [today].
  bool isDueToday(DateTime today) => !isDelivered && daysLate(today) == 0;

  /// Not delivered and due after [today].
  bool isUpcoming(DateTime today) => !isDelivered && daysLate(today) < 0;

  static DateTime _day(DateTime time) =>
      DateTime.utc(time.year, time.month, time.day);
}

/// Open orders first: the most overdue at the top, then by delivery date
/// and, on the same day, the furthest along. Delivered orders follow, the
/// most recent first.
int compareForWorklist(Order a, Order b) {
  if (a.isDelivered != b.isDelivered) return a.isDelivered ? 1 : -1;
  if (a.isDelivered) {
    return (b.deliveredAt ?? b.deliveryDate).compareTo(
      a.deliveredAt ?? a.deliveryDate,
    );
  }
  final byDate = a.deliveryDate.compareTo(b.deliveryDate);
  if (byDate != 0) return byDate;
  return OrderStatus.production
      .indexOf(b.status)
      .compareTo(OrderStatus.production.indexOf(a.status));
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer_activity.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';

/// Each customer's activity today, by customer id. A customer without orders
/// or measurements has no entry.
final customerActivityProvider = Provider<Map<String, CustomerActivity>>((
  ref,
) {
  return CustomerActivity.byCustomer(
    orders: ref.watch(ordersNotifierProvider).valueOrNull ?? const [],
    measurements: ref.watch(measurementsNotifierProvider).valueOrNull ?? const [],
    today: ref.watch(clockProvider)(),
  );
});

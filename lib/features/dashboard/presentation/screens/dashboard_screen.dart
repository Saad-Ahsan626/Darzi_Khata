import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/dashboard/presentation/widgets/dashboard_delivery_card.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersNotifierProvider);
    final customersAsync = ref.watch(customersNotifierProvider);

    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.carbon,
        elevation: 0,
        title: const Text(
          'Tailor Khata',
          style: TextStyle(
            color: AppPalette.white,
            fontFamily: AppTypography.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppPalette.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'TK',
                  style: TextStyle(
                    color: AppPalette.carbon,
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppPalette.carbon),
        ),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (orders) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // "This Month" revenue based on actual cash collected for orders created this month
          double monthRevenue = 0;
          for (var order in orders) {
            final advance = order.advancePaid;
            if (advance > 0 &&
                order.createdAt.year == now.year &&
                order.createdAt.month == now.month) {
              monthRevenue += advance;
            }
          }

          // "Pending Payments"
          double pendingTotal = 0;
          Set<String> pendingCustomers = {};
          for (var order in orders) {
            final balance = order.totalAmount - order.advancePaid;
            if (balance > 0) {
              pendingTotal += balance;
              pendingCustomers.add(order.customerId);
            }
          }

          // "Today's Deliveries"
          final todaysDeliveries = orders.where((order) {
            final dDate = DateTime(
              order.deliveryDate.year,
              order.deliveryDate.month,
              order.deliveryDate.day,
            );
            return dDate.isAtSameMomentAs(today);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary Row
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/home/revenue');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppPalette.carbon,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'THIS MONTH',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.onCarbonMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rs ${monthRevenue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontFeatures: AppTypography.tabularFigures,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppPalette.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Text(
                                    'View all',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      fontSize: 13,
                                      color: AppPalette.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppPalette.white,
                                    size: 10,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppPalette.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppPalette.lineStrong),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PENDING PAYMENTS',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.ink70,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rs $pendingTotal',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontFeatures: AppTypography.tabularFigures,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppPalette.carbon,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'across ${pendingCustomers.length} customers',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13,
                                color: AppPalette.ink70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Today's Deliveries Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Today\'s Deliveries',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.carbon,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Today's Deliveries List
                if (todaysDeliveries.isEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppPalette.lineStrong),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: const Text(
                        'No deliveries today — a calm day at the counter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppPalette.ink70,
                          fontSize: 15,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ),
                  )
                else
                  ...todaysDeliveries.map((order) {
                    final customers = customersAsync.value ?? [];
                    final customerList = customers
                        .where((c) => c.id == order.customerId)
                        .toList();
                    final customerName = customerList.isNotEmpty
                        ? customerList.first.name
                        : 'Unknown Customer';

                    return DashboardDeliveryCard(
                      order: order,
                      customerName: customerName,
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

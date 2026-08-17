import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/dashboard/presentation/widgets/dashboard_delivery_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersNotifierProvider);
    final customersAsync = ref.watch(customersNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.tailorChalk,
      appBar: AppBar(
        backgroundColor: AppColors.charcoalThread,
        elevation: 0,
        title: const Text(
          'Tailor Khata',
          style: TextStyle(
            color: AppColors.tailorChalk,
            fontFamily: 'Zilla Slab',
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 12.0),
            child: Center(
              child: Text(
                'ٹیلر کھاتہ',
                style: TextStyle(
                  color: AppColors.brassTape,
                  fontFamily: 'Noto Nastaliq Urdu',
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brassTape,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'TK',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Zilla Slab',
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.brassTape)),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (orders) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          // "This Month" revenue based on createdAt
          double monthRevenue = 0;
          int monthCount = 0;
          for (var order in orders) {
            if (order.createdAt.year == now.year && order.createdAt.month == now.month) {
              monthRevenue += order.totalAmount;
              monthCount++;
            }
          }

          // "Pending Payments"
          double pendingTotal = 0;
          Set<String> pendingCustomers = {};
          for (var order in orders) {
            if (order.status != 'Delivered') {
              final balance = order.totalAmount - order.advancePaid;
              if (balance > 0) {
                pendingTotal += balance;
                pendingCustomers.add(order.customerId);
              }
            }
          }

          // "Today's Deliveries"
          final todaysDeliveries = orders.where((order) {
            final dDate = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
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
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.stitchNavy,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THIS MONTH',
                              style: TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ghost,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rs $monthRevenue',
                              style: const TextStyle(
                                fontFamily: 'Roboto Mono',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tailorChalk,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$monthCount orders',
                              style: const TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 13,
                                color: AppColors.ghost,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.fabricGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PENDING PAYMENTS',
                              style: TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.inkMuted,
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rs $pendingTotal',
                              style: const TextStyle(
                                fontFamily: 'Roboto Mono',
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.seamRed,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'across ${pendingCustomers.length} customers',
                              style: const TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 13,
                                color: AppColors.inkMuted,
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
                        fontFamily: 'Zilla Slab',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.charcoalThread,
                      ),
                    ),
                    Text(
                      'آج کی ڈیلیوری',
                      style: TextStyle(
                        fontFamily: 'Noto Nastaliq Urdu',
                        fontSize: 16,
                        color: AppColors.charcoalThread,
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
                        border: Border.all(color: AppColors.fabricGrey),
                        borderRadius: BorderRadius.circular(14)
                      ),
                      padding: const EdgeInsets.all(24),
                      child: const Text(
                        'No deliveries today — a calm day at the counter.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.ghost,
                          fontSize: 15,
                          fontFamily: 'Noto Sans',
                        ),
                      ),
                    )
                  )
                else
                  ...todaysDeliveries.map((order) {
                    final customers = customersAsync.value ?? [];
                    final customerList = customers.where((c) => c.id == order.customerId).toList();
                    final customerName = customerList.isNotEmpty ? customerList.first.name : 'Unknown Customer';
                    
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

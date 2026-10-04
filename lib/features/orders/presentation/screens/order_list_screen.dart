import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_card.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_filter_tabs.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  int _selectedFilterIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersNotifierProvider);

    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.carbon,
        elevation: 0,
        title: const Text(
          'Orders',
          style: TextStyle(
            color: AppPalette.white,
            fontFamily: AppTypography.fontFamily,
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New order',
            icon: const Icon(Icons.add, color: AppPalette.white),
            onPressed: () => context.push('/orders/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          OrderFilterTabs(
            selectedIndex: _selectedFilterIndex,
            onChanged: (index) {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppPalette.carbon),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Text(
                    'Could not load orders.\n${err.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppPalette.carbon),
                  ),
                ),
              ),
              data: (orders) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                final displayOrders = orders.where((order) {
                  final orderDate = DateTime(
                    order.deliveryDate.year,
                    order.deliveryDate.month,
                    order.deliveryDate.day,
                  );

                  switch (_selectedFilterIndex) {
                    case 1: // Today
                      return orderDate.isAtSameMomentAs(today);
                    case 2: // This Week
                      final weekFromNow = today.add(const Duration(days: 7));
                      return (orderDate.isAtSameMomentAs(today) ||
                              orderDate.isAfter(today)) &&
                          (orderDate.isBefore(weekFromNow) ||
                              orderDate.isAtSameMomentAs(weekFromNow));
                    case 3: // Overdue
                      return orderDate.isBefore(today) &&
                          order.status != 'Delivered';
                    case 0: // All
                    default:
                      return true;
                  }
                }).toList();

                if (displayOrders.isEmpty) {
                  return Center(
                    child: AppFeedback(
                      title: 'No orders here',
                      message: 'Create an order or choose another filter.',
                      actionLabel: 'New order',
                      onAction: () => context.push('/orders/new'),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: displayOrders.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = displayOrders[index];
                    return OrderCard(order: order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
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
      backgroundColor: AppColors.tailorChalk,
      appBar: AppBar(
        backgroundColor: AppColors.charcoalThread,
        elevation: 0,
        title: const Text(
          'Orders',
          style: TextStyle(
            color: AppColors.tailorChalk,
            fontFamily: 'Zilla Slab',
            fontSize: 21,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18.0),
            child: Center(
              child: Text(
                'آرڈر',
                style: TextStyle(
                  color: AppColors.brassTape,
                  fontFamily: 'Noto Nastaliq Urdu',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                child: CircularProgressIndicator(color: AppColors.brassTape),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Text(
                    'Could not load orders.\n${err.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.seamRed),
                  ),
                ),
              ),
              data: (orders) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                
                final displayOrders = orders.where((order) {
                  final orderDate = DateTime(order.deliveryDate.year, order.deliveryDate.month, order.deliveryDate.day);
                  
                  switch (_selectedFilterIndex) {
                    case 1: // Today
                      return orderDate.isAtSameMomentAs(today);
                    case 2: // This Week
                      final weekFromNow = today.add(const Duration(days: 7));
                      return (orderDate.isAtSameMomentAs(today) || orderDate.isAfter(today)) && 
                             (orderDate.isBefore(weekFromNow) || orderDate.isAtSameMomentAs(weekFromNow));
                    case 3: // Overdue
                      return orderDate.isBefore(today) && order.status != 'Delivered';
                    case 0: // All
                    default:
                      return true;
                  }
                }).toList();

                if (displayOrders.isEmpty) {
                  return _buildEmptyState();
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.fabricGrey, width: 1),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 48, color: AppColors.ghost),
              SizedBox(height: 16),
              Text(
                'No orders here yet — tap + to create your first one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ghost,
                  fontSize: 15,
                  fontFamily: 'Noto Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

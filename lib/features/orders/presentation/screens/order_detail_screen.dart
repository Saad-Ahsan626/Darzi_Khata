import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart'
    as order_entity;
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/status_stepper.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key});

  Future<int?> _showDeliveryConfirmation(BuildContext context, double balance) {
    if (balance <= 0) {
      // If already fully paid, just ask for normal confirmation
      return showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.charcoalThread,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Delivery', style: TextStyle(color: AppColors.tailorChalk, fontFamily: 'Zilla Slab')),
          content: const Text(
            'Are you sure you want to mark this order as Delivered?\n\nOnce marked as Delivered, you cannot change its status again.',
            style: TextStyle(color: AppColors.ghost, fontFamily: 'Noto Sans'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0), // 0 = Cancel
              child: const Text('Cancel', style: TextStyle(color: AppColors.fabricGrey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 2), // 2 = Mark delivered (no payment needed)
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brassTape),
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // If there is a pending balance
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.charcoalThread,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Payment Collection', style: TextStyle(color: AppColors.tailorChalk, fontFamily: 'Zilla Slab')),
        content: Text(
          'Remaining Balance: Rs ${balance.toStringAsFixed(0)}\n\nHas the customer paid the remaining balance?',
          style: const TextStyle(color: AppColors.ghost, fontFamily: 'Noto Sans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0), // 0 = Cancel
            child: const Text('Cancel', style: TextStyle(color: AppColors.fabricGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 1), // 1 = Delivered but NOT Paid
            child: const Text('Not Paid', style: TextStyle(color: AppColors.seamRed)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 2), // 2 = Delivered AND Paid
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brassTape),
            child: const Text('Paid & Deliver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderId = GoRouterState.of(context).pathParameters['id'];
    final ordersAsync = ref.watch(ordersNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.tailorChalk,
      appBar: AppBar(
        backgroundColor: AppColors.charcoalThread,
        elevation: 0,
        leading: IconButton(
          icon: const Row(
            children: [Icon(Icons.chevron_left, color: AppColors.brassTape)],
          ),
          onPressed: () => context.pop(),
        ),
        title: ordersAsync.when(
          data: (orders) {
            final orderList = orders.where((o) => o.id == orderId).toList();
            if (orderList.isEmpty) return const Text('');
            return Text(
              orderList.first.garmentType,
              style: const TextStyle(
                color: AppColors.tailorChalk,
                fontFamily: 'Zilla Slab',
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            );
          },
          loading: () => const Text(''),
          error: (e, s) =>
              const Text('Error', style: TextStyle(color: AppColors.seamRed)),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brassTape),
        ),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (orders) {
          final orderList = orders.where((o) => o.id == orderId).toList();
          if (orderList.isEmpty) {
            return const Center(child: Text('Order not found'));
          }
          final order = orderList.first;

          final customersAsync = ref.watch(customersNotifierProvider);

          return Column(
            children: [
              // Header area
              Container(
                width: double.infinity,
                color: AppColors.charcoalThread,
                padding: const EdgeInsets.only(left: 56, right: 16, bottom: 16),
                child: customersAsync.when(
                  data: (customers) {
                    final cList = customers
                        .where((c) => c.id == order.customerId)
                        .toList();
                    final cName = cList.isNotEmpty
                        ? cList.first.name
                        : 'Unknown Customer';
                    final cPhone = cList.isNotEmpty ? cList.first.phone : '';
                    return Text(
                      '$cName · $cPhone',
                      style: const TextStyle(
                        color: AppColors.ghost,
                        fontFamily: 'Noto Sans',
                        fontSize: 13,
                      ),
                    );
                  },
                  loading: () => const Text(
                    'Loading customer...',
                    style: TextStyle(color: AppColors.ghost),
                  ),
                  error: (e, s) => const Text(
                    'Customer error',
                    style: TextStyle(color: AppColors.seamRed),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.fabricGrey),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Fabric',
                                    style: TextStyle(
                                      color: AppColors.inkMuted,
                                      fontSize: 13,
                                      fontFamily: 'Noto Sans',
                                    ),
                                  ),
                                  Text(
                                    order.notes?.isNotEmpty == true
                                        ? order.notes!
                                        : 'Not specified',
                                    style: const TextStyle(
                                      color: AppColors.charcoalThread,
                                      fontSize: 15,
                                      fontFamily: 'Noto Sans',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Tape Divider
                            Container(
                              height: 7,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Color(0x80B8863B),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              child: CustomPaint(
                                painter: _TapeDividerPainter(),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildFinancialColumn(
                                      'Total',
                                      'Rs ${order.totalAmount}',
                                      AppColors.charcoalThread,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildFinancialColumn(
                                      'Advance',
                                      'Rs ${order.advancePaid}',
                                      AppColors.stitchNavy,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildFinancialColumn(
                                      'Balance',
                                      'Rs ${order.totalAmount - order.advancePaid}',
                                      (order.totalAmount - order.advancePaid) <=
                                              0
                                          ? AppColors.greenOk
                                          : AppColors.seamRed,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      StatusStepper(
                        currentStatus: order.status,
                        onStatusChanged: (newStatus) async {
                          int paymentResult = 2; // Default assume paid or no balance
                          if (newStatus == 'Delivered') {
                            final balance = order.totalAmount - order.advancePaid;
                            final confirmed = await _showDeliveryConfirmation(context, balance);
                            if (confirmed == null || confirmed == 0) return;
                            paymentResult = confirmed;
                          }
                          final updatedOrder = order_entity.Order(
                            id: order.id,
                            customerId: order.customerId,
                            measurementId: order.measurementId,
                            garmentType: order.garmentType,
                            status: newStatus,
                            deliveryDate: order.deliveryDate,
                            totalAmount: order.totalAmount,
                            advancePaid: paymentResult == 2 ? order.totalAmount : order.advancePaid,
                            notes: order.notes,
                            createdAt: order.createdAt,
                            deliveredAt: newStatus == 'Delivered' ? DateTime.now() : order.deliveredAt,
                            ownerId: order.ownerId,
                            syncStatus: order.syncStatus,
                          );
                          ref
                              .read(ordersNotifierProvider.notifier)
                              .updateOrder(updatedOrder);
                        },
                      ),
                      const SizedBox(height: 32),

                      if (order.status != 'Delivered')
                        ElevatedButton(
                          onPressed: () async {
                            final balance = order.totalAmount - order.advancePaid;
                            final confirmed = await _showDeliveryConfirmation(context, balance);
                            if (confirmed == null || confirmed == 0) return;

                            final updatedOrder = order_entity.Order(
                              id: order.id,
                              customerId: order.customerId,
                              measurementId: order.measurementId,
                              garmentType: order.garmentType,
                              status: 'Delivered',
                              deliveryDate: order.deliveryDate,
                              totalAmount: order.totalAmount,
                              advancePaid: confirmed == 2 ? order.totalAmount : order.advancePaid,
                              notes: order.notes,
                              createdAt: order.createdAt,
                              deliveredAt: DateTime.now(),
                              ownerId: order.ownerId,
                              syncStatus: order.syncStatus,
                            );
                            ref
                                .read(ordersNotifierProvider.notifier)
                                .updateOrder(updatedOrder);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.stitchNavy,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Mark as Delivered',
                            style: TextStyle(
                              fontFamily: 'Noto Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (order.status != 'Delivered')
                        const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reminder sent via WhatsApp'),
                              backgroundColor: AppColors.charcoalThread,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenOk,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Send Reminder',
                              style: TextStyle(
                                fontFamily: 'Noto Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFinancialColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.inkMuted,
            fontSize: 11,
            fontFamily: 'Noto Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontFamily: 'Roboto Mono',
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TapeDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x80B8863B)
      ..strokeWidth = 1.5;

    for (double i = 0; i < size.width; i += 9) {
      canvas.drawLine(
        Offset(i, size.height - 3),
        Offset(i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
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
          title: const Text(
            'Confirm Delivery',
            style: TextStyle(
              color: AppPalette.carbon,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
          content: const Text(
            'Are you sure you want to mark this order as Delivered?\n\nOnce marked as Delivered, you cannot change its status again.',
            style: TextStyle(
              color: AppPalette.ink70,
              fontFamily: AppTypography.fontFamily,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 0), // 0 = Cancel
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppPalette.ink70),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                ctx,
                2,
              ), // 2 = Mark delivered (no payment needed)
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPalette.carbon,
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: AppPalette.white),
              ),
            ),
          ],
        ),
      );
    }

    // If there is a pending balance
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Payment Collection',
          style: TextStyle(
            color: AppPalette.carbon,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
        content: Text(
          'Remaining Balance: Rs ${balance.toStringAsFixed(0)}\n\nHas the customer paid the remaining balance?',
          style: const TextStyle(
            color: AppPalette.ink70,
            fontFamily: AppTypography.fontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0), // 0 = Cancel
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppPalette.ink70),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, 1), // 1 = Delivered but NOT Paid
            child: const Text(
              'Not Paid',
              style: TextStyle(color: AppPalette.carbon),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 2), // 2 = Delivered AND Paid
            style: ElevatedButton.styleFrom(backgroundColor: AppPalette.carbon),
            child: const Text(
              'Paid & Deliver',
              style: TextStyle(color: AppPalette.white),
            ),
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
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.carbon,
        elevation: 0,
        leading: IconButton(
          icon: const Row(
            children: [Icon(Icons.chevron_left, color: AppPalette.white)],
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
                color: AppPalette.white,
                fontFamily: AppTypography.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            );
          },
          loading: () => const Text(''),
          error: (e, s) =>
              const Text('Error', style: TextStyle(color: AppPalette.white)),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppPalette.carbon),
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
                color: AppPalette.carbon,
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
                        color: AppPalette.onCarbonMuted,
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                      ),
                    );
                  },
                  loading: () => const Text(
                    'Loading customer...',
                    style: TextStyle(color: AppPalette.onCarbonMuted),
                  ),
                  error: (e, s) => const Text(
                    'Customer error',
                    style: TextStyle(color: AppPalette.white),
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
                          color: AppPalette.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppPalette.lineStrong),
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
                                      color: AppPalette.ink70,
                                      fontSize: 13,
                                      fontFamily: AppTypography.fontFamily,
                                    ),
                                  ),
                                  Text(
                                    order.fabric?.isNotEmpty == true
                                        ? order.fabric!
                                        : 'Not specified',
                                    style: const TextStyle(
                                      color: AppPalette.carbon,
                                      fontSize: 15,
                                      fontFamily: AppTypography.fontFamily,
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
                                    color: AppPalette.oliveBorder,
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
                                      AppPalette.carbon,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildFinancialColumn(
                                      'Advance',
                                      'Rs ${order.paidAmount}',
                                      AppPalette.carbon,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildFinancialColumn(
                                      'Balance',
                                      'Rs ${order.totalAmount - order.paidAmount}',
                                      (order.totalAmount - order.paidAmount) <=
                                              0
                                          ? AppPalette.oliveInk
                                          : AppPalette.carbon,
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
                          final orders = ref.read(
                            ordersNotifierProvider.notifier,
                          );
                          // Production stages never change the paid amount;
                          // only a delivery confirmed as paid settles it.
                          if (newStatus != 'Delivered') {
                            orders.changeStatus(order.id, newStatus);
                            return;
                          }
                          final balance = order.totalAmount - order.paidAmount;
                          final confirmed = await _showDeliveryConfirmation(
                            context,
                            balance,
                          );
                          if (confirmed == null || confirmed == 0) return;
                          orders.deliverOrder(
                            order.id,
                            settleBalance: confirmed == 2,
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // If order is Delivered but still has a balance, show Collect Payment button
                      if (order.status == 'Delivered' &&
                          (order.totalAmount - order.paidAmount) > 0)
                        ElevatedButton(
                          onPressed: () async {
                            final balance =
                                order.totalAmount - order.paidAmount;
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text(
                                  'Collect Payment',
                                  style: TextStyle(
                                    color: AppPalette.carbon,
                                    fontFamily: AppTypography.fontFamily,
                                  ),
                                ),
                                content: Text(
                                  'Collect the pending due of Rs ${balance.toStringAsFixed(0)}?',
                                  style: const TextStyle(
                                    color: AppPalette.ink70,
                                    fontFamily: AppTypography.fontFamily,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(color: AppPalette.ink70),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppPalette.carbon,
                                    ),
                                    child: const Text(
                                      'Mark as Paid',
                                      style: TextStyle(color: AppPalette.white),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              ref
                                  .read(ordersNotifierProvider.notifier)
                                  .recordPayment(
                                    order.id,
                                    balance,
                                    PaymentMethod.cash,
                                  );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.carbon,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Collect Due Amount',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.white,
                            ),
                          ),
                        ),

                      if (order.status == 'Delivered' &&
                          (order.totalAmount - order.paidAmount) > 0)
                        const SizedBox(height: 12),

                      if (order.status != 'Delivered')
                        ElevatedButton(
                          onPressed: () async {
                            final balance =
                                order.totalAmount - order.paidAmount;
                            final confirmed = await _showDeliveryConfirmation(
                              context,
                              balance,
                            );
                            if (confirmed == null || confirmed == 0) return;

                            ref
                                .read(ordersNotifierProvider.notifier)
                                .deliverOrder(
                                  order.id,
                                  settleBalance: confirmed == 2,
                                );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPalette.carbon,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Mark as Delivered',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppPalette.white,
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
                              backgroundColor: AppPalette.carbon,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPalette.oliveInk,
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
                              color: AppPalette.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Send Reminder',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppPalette.white,
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
            color: AppPalette.ink70,
            fontSize: 11,
            fontFamily: AppTypography.fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontFamily: AppTypography.fontFamily,
            fontFeatures: AppTypography.tabularFigures,
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
      ..color = AppPalette.oliveBorder
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

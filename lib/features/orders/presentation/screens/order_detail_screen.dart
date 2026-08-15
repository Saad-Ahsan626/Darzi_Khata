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
                        onStatusChanged: (newStatus) {
                          final updatedOrder = order_entity.Order(
                            id: order.id,
                            customerId: order.customerId,
                            measurementId: order.measurementId,
                            garmentType: order.garmentType,
                            status: newStatus,
                            deliveryDate: order.deliveryDate,
                            totalAmount: order.totalAmount,
                            advancePaid: order.advancePaid,
                            notes: order.notes,
                            createdAt: order.createdAt,
                            ownerId: order.ownerId,
                            syncStatus: order.syncStatus,
                          );
                          ref
                              .read(ordersNotifierProvider.notifier)
                              .updateOrder(updatedOrder);
                        },
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: () {
                          final updatedOrder = order_entity.Order(
                            id: order.id,
                            customerId: order.customerId,
                            measurementId: order.measurementId,
                            garmentType: order.garmentType,
                            status: 'Delivered',
                            deliveryDate: order.deliveryDate,
                            totalAmount: order.totalAmount,
                            advancePaid: order.advancePaid,
                            notes: order.notes,
                            createdAt: order.createdAt,
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

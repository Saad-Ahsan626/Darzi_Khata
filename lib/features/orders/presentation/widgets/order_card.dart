import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:intl/intl.dart';

class OrderCard extends ConsumerWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine status color
    Color statusColor;
    Color statusBgColor;
    switch (order.status) {
      case 'Delivered':
      case 'Ready':
        statusColor = AppPalette.oliveInk;
        statusBgColor = AppPalette.surfaceSunken;
        break;
      case 'Cutting':
      case 'Stitching':
        statusColor = AppPalette.carbon;
        statusBgColor = AppPalette.surfaceControl;
        break;
      default:
        statusColor = AppPalette.carbon;
        statusBgColor = AppPalette.surfaceControl;
        break;
    }

    final balance = order.totalAmount - order.advancePaid;
    final isPaid = balance <= 0;

    final customersAsync = ref.watch(customersNotifierProvider);
    String customerName = 'Unknown Customer';
    customersAsync.whenData((customers) {
      final cList = customers.where((c) => c.id == order.customerId).toList();
      if (cList.isNotEmpty) {
        customerName = cList.first.name;
      }
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delivery = DateTime(
      order.deliveryDate.year,
      order.deliveryDate.month,
      order.deliveryDate.day,
    );

    Color deliveryColor = AppPalette.carbon;
    String deliveryLabel = DateFormat('MMM d, yyyy').format(order.deliveryDate);

    if (delivery.isBefore(today) && order.status != 'Delivered') {
      deliveryColor = AppPalette.carbon;
      deliveryLabel =
          'Overdue · ${DateFormat('MMM d').format(order.deliveryDate)}';
    } else if (delivery.isAtSameMomentAs(today)) {
      deliveryColor = AppPalette.carbon;
      deliveryLabel = 'Due today';
    }

    return GestureDetector(
      onTap: () {
        context.go('/orders/${order.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.lineStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.carbon,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.garmentType,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 13,
                            color: AppPalette.ink70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: statusColor,
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
                  bottom: BorderSide(color: AppPalette.oliveBorder, width: 1.5),
                ),
              ),
              child: CustomPaint(painter: _TapeDividerPainter()),
            ),

            // Bottom Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delivery Date
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: deliveryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        deliveryLabel,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontFeatures: AppTypography.tabularFigures,
                          fontSize: 13,
                          color: deliveryColor,
                        ),
                      ),
                    ],
                  ),
                  // Balance
                  Text(
                    isPaid ? 'Paid' : 'Rs $balance due',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontFeatures: AppTypography.tabularFigures,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPaid ? AppPalette.oliveInk : AppPalette.carbon,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapeDividerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppPalette
          .oliveBorder // Olive divider
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

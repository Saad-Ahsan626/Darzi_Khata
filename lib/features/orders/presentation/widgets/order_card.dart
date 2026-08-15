import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // Determine status color
    Color statusColor;
    Color statusBgColor;
    switch (order.status) {
      case 'Delivered':
      case 'Ready':
        statusColor = AppColors.greenOk;
        statusBgColor = AppColors.greenBg;
        break;
      case 'Cutting':
      case 'Stitching':
        statusColor = AppColors.brassTape;
        statusBgColor = AppColors.brassBg;
        break;
      default:
        statusColor = AppColors.stitchNavy;
        statusBgColor = AppColors.navyBg;
        break;
    }

    final balance = order.totalAmount - order.advancePaid;
    final isPaid = balance <= 0;

    // In a real app we'd fetch the customer name via customerId
    final customerName = 'Customer ${order.customerId.substring(0, 4)}';

    return GestureDetector(
      onTap: () {
        context.go('/orders/${order.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fabricGrey),
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
                            fontFamily: 'Noto Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.charcoalThread,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.garmentType,
                          style: const TextStyle(
                            fontFamily: 'Noto Sans',
                            fontSize: 13,
                            color: AppColors.inkMuted,
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
                        fontFamily: 'Noto Sans',
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
                  bottom: BorderSide(color: Color(0x80B8863B), width: 1.5),
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
                        decoration: const BoxDecoration(
                          color: AppColors.charcoalThread,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d, yyyy').format(order.deliveryDate),
                        style: const TextStyle(
                          fontFamily: 'Roboto Mono',
                          fontSize: 13,
                          color: AppColors.charcoalThread,
                        ),
                      ),
                    ],
                  ),
                  // Balance
                  Text(
                    isPaid ? 'Paid' : 'Rs $balance due',
                    style: TextStyle(
                      fontFamily: 'Roboto Mono',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPaid ? AppColors.greenOk : AppColors.seamRed,
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
      ..color =
          const Color(0x80B8863B) // brass at 50% opacity
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

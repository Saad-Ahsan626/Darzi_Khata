import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:intl/intl.dart';

class DashboardDeliveryCard extends StatelessWidget {
  final Order order;
  final String customerName;

  const DashboardDeliveryCard({
    super.key,
    required this.order,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final balance = order.totalAmount - order.advancePaid;
    final isPaid = balance <= 0;

    return GestureDetector(
      onTap: () {
        context.push('/orders/${order.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.lineStrong),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppPalette.carbon, width: 4),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Time
                Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  child: Text(
                    DateFormat('h:mm a').format(order.deliveryDate),
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontFeatures: AppTypography.tabularFigures,
                      fontSize: 13,
                      color: AppPalette.carbon,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Details
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isPaid ? 'PAID' : 'BALANCE',
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.ink70,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPaid ? 'Rs ${order.totalAmount}' : 'Rs $balance',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontFeatures: AppTypography.tabularFigures,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? AppPalette.oliveInk : AppPalette.carbon,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

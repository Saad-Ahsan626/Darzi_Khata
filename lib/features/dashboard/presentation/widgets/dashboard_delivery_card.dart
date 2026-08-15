import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:intl/intl.dart';

class DashboardDeliveryCard extends ConsumerWidget {
  final Order order;

  const DashboardDeliveryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return GestureDetector(
      onTap: () {
        context.push('/orders/${order.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fabricGrey),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.brassTape, width: 4),
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
                      fontFamily: 'Roboto Mono',
                      fontSize: 13,
                      color: AppColors.brassTape,
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
                        fontFamily: 'Noto Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPaid ? 'Rs ${order.totalAmount}' : 'Rs $balance',
                      style: TextStyle(
                        fontFamily: 'Roboto Mono',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? AppColors.greenOk : AppColors.seamRed,
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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_avatar.dart';
import 'package:go_router/go_router.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;

  const CustomerCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/customers/${customer.id}', extra: customer);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPalette.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppPalette.lineStrong, width: 1),
        ),
        child: Row(
          children: [
            CustomerAvatar(customer: customer),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          customer.name,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.carbon,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.phone?.isNotEmpty == true
                        ? customer.phone!
                        : 'No phone number',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontFeatures: AppTypography.tabularFigures,
                      fontSize: 13,
                      color: AppPalette.ink70,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'ADDED',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: AppPalette.ink70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d').format(customer.createdAt),
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontFeatures: AppTypography.tabularFigures,
                    fontSize: 13,
                    color: AppPalette.carbon,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

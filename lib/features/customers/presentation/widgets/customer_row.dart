import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer_activity.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_avatar.dart';

/// One customer in the list: avatar, name, phone and what needs attention.
class CustomerRow extends StatelessWidget {
  final Customer customer;
  final CustomerActivity activity;
  final VoidCallback onTap;

  const CustomerRow({
    super.key,
    required this.customer,
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final phone = formatPhone(customer.phone);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            CustomerAvatar(
              customer: customer,
              tone: activity.isActive
                  ? CustomerAvatarTone.active
                  : CustomerAvatarTone.quiet,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: AppTypography.body.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 15.5 * -0.012,
                      color: AppPalette.carbon,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone.isEmpty ? 'No phone number' : phone,
                    style: AppTypography.support.copyWith(
                      fontSize: 12.5,
                      fontFeatures: AppTypography.tabularFigures,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _StatusLine(activity),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppPalette.ink45,
            ),
          ],
        ),
      ),
    );
  }
}

/// The single most useful fact about the customer right now.
class _StatusLine extends StatelessWidget {
  const _StatusLine(this.activity);
  final CustomerActivity activity;

  static String _count(int count, String one, String many) =>
      '$count ${count == 1 ? one : many}';

  @override
  Widget build(BuildContext context) {
    final due = activity.outstanding > 0
        ? formatRupees(activity.outstanding)
        : null;
    final IconData? icon;
    final String text;
    var needsAttention = true;

    if (activity.overdueDays > 0) {
      icon = Icons.schedule;
      text = [
        'Overdue ${_count(activity.overdueDays, 'day', 'days')}',
        ?due,
      ].join(' · ');
    } else if (activity.deliveryToday) {
      icon = Icons.circle;
      text = ['Delivery today', if (due != null) '$due due'].join(' · ');
    } else if (activity.openOrderCount > 0) {
      icon = Icons.circle;
      text = [
        _count(activity.openOrderCount, 'open order', 'open orders'),
        if (due != null) '$due due',
      ].join(' · ');
    } else if (due != null) {
      icon = Icons.circle;
      text = '$due due';
    } else {
      icon = null;
      needsAttention = false;
      if (activity.lastOrderDate != null) {
        final date = DateFormat('d MMM').format(activity.lastOrderDate!);
        text = 'Last order $date · no balance';
      } else if (activity.measurementProfileCount > 0) {
        final profiles = _count(
          activity.measurementProfileCount,
          'measurement profile',
          'measurement profiles',
        );
        text = '$profiles saved';
      } else {
        text = 'No orders yet';
      }
    }

    final color = needsAttention ? AppPalette.carbon : AppPalette.ink55;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: icon == Icons.circle ? 5 : 12, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: AppTypography.micro.copyWith(
              fontSize: 11.5,
              fontWeight: needsAttention ? FontWeight.w600 : FontWeight.w500,
              fontFeatures: AppTypography.tabularFigures,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

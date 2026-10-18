import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_timing.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_status_badge.dart';

/// "Overdue 2 days", on a carbon badge.
class OverdueBadge extends StatelessWidget {
  const OverdueBadge({super.key, required this.days});
  final int days;

  @override
  Widget build(BuildContext context) => AppStatusBadge(
    label: 'Overdue $days ${days == 1 ? 'day' : 'days'}',
    icon: Icons.schedule,
    tone: AppBadgeTone.strong,
  );
}

/// One order in the shop's list, read left to right: customer, garment,
/// stage, date, balance. Late orders are outlined and say so.
class OrderListCard extends StatelessWidget {
  const OrderListCard({
    super.key,
    required this.order,
    required this.customerName,
    required this.orderLabel,
    required this.today,
    required this.onTap,
    this.onRemind,
  });

  final Order order;
  final String customerName;

  /// The order number as the shop shows it, such as `DK-0042`.
  final String? orderLabel;
  final DateTime today;
  final VoidCallback onTap;

  /// Offers a WhatsApp reminder in place of the stage and date.
  final VoidCallback? onRemind;

  static final _dayMonth = DateFormat('d MMM');

  @override
  Widget build(BuildContext context) {
    final late = order.isOverdue(today);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: late
          ? const BorderSide(color: AppPalette.carbon, width: 1.5)
          : const BorderSide(color: AppPalette.line),
    );
    final pieces = '${order.pieces} ${order.pieces == 1 ? 'pc' : 'pcs'}';

    return Material(
      color: late ? AppPalette.surfaceSunken : AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 15.5 * -0.012,
                            color: AppPalette.carbon,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [order.garmentType, pieces, ?orderLabel].join(' · '),
                          style: AppTypography.support.copyWith(
                            fontSize: 12.5,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _Balance(order: order),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 11),
                child: AppDashedLine(),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final support = AppTypography.support.copyWith(
      fontSize: 11.5,
      fontFeatures: AppTypography.tabularFigures,
    );
    final strong = support.copyWith(
      fontWeight: FontWeight.w600,
      color: AppPalette.carbon,
    );
    final action = support.copyWith(
      fontWeight: FontWeight.w600,
      color: AppPalette.oliveInk,
    );
    final daysLate = order.daysLate(today);
    final date = _dayMonth.format(order.deliveryDate);

    final (List<Widget> lead, Widget? trailing) = switch (order) {
      _ when order.isDelivered => (
        [
          OrderStatusBadge(order.status),
          Text(
            _dayMonth.format(order.deliveredAt ?? order.deliveryDate),
            style: support,
          ),
        ],
        null,
      ),
      _ when daysLate > 0 && onRemind != null => (
        [OverdueBadge(days: daysLate)],
        TextButton(
          onPressed: onRemind,
          style: TextButton.styleFrom(
            foregroundColor: AppPalette.oliveInk,
            minimumSize: const Size(AppSizing.minHitTarget, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text('Remind ›', style: action),
        ),
      ),
      _ when daysLate > 0 => (
        [OverdueBadge(days: daysLate), OrderStatusBadge(order.status)],
        Text(date, style: support),
      ),
      _ when daysLate == 0 => (
        [OrderStatusBadge(order.status), Text('Today, $date', style: strong)],
        Text(
          order.status == OrderStatus.ready ? 'Deliver ›' : 'Update ›',
          style: support,
        ),
      ),
      _ => (
        [
          OrderStatusBadge(order.status),
          Text(
            daysLate == -1 ? 'Tomorrow, $date' : '$date · in ${-daysLate} days',
            style: support,
          ),
        ],
        null,
      ),
    };

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: lead,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final paid = order.balance <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          paid ? 'Paid' : formatRupees(order.balance),
          style: AppTypography.numberMd.copyWith(
            fontSize: 15.5,
            color: paid ? AppPalette.ink45 : AppPalette.carbon,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          paid ? 'in full' : 'balance',
          style: AppTypography.support.copyWith(
            fontSize: 10.5,
            color: AppPalette.ink55,
          ),
        ),
      ],
    );
  }
}

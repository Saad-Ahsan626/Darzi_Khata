import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_status_badge.dart';

/// One order in a customer's history.
class CustomerOrderCard extends StatelessWidget {
  final Order order;

  /// The order number as the shop shows it, such as `TK-0042`.
  final String? orderLabel;
  final DateTime today;
  final VoidCallback onTap;

  const CustomerOrderCard({
    super.key,
    required this.order,
    required this.orderLabel,
    required this.today,
    required this.onTap,
  });

  static final _dayMonth = DateFormat('d MMM');

  bool get _delivered => order.status == OrderStatus.delivered;

  /// Days past the delivery date; negative while it is still ahead.
  int get _daysLate => DateTime.utc(today.year, today.month, today.day)
      .difference(
        DateTime.utc(
          order.deliveryDate.year,
          order.deliveryDate.month,
          order.deliveryDate.day,
        ),
      )
      .inDays;

  String get _dueText {
    final date = _dayMonth.format(order.deliveryDate);
    if (_daysLate > 0) {
      return 'Overdue $_daysLate ${_daysLate == 1 ? 'day' : 'days'} · $date';
    }
    return _daysLate == 0 ? 'Deliver today, $date' : 'Due $date';
  }

  @override
  Widget build(BuildContext context) {
    // Ready, due today or late: the orders to act on first.
    final needsAttention =
        !_delivered && (order.status == OrderStatus.ready || _daysLate >= 0);
    final paid = order.balance <= 0;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: needsAttention
          ? const BorderSide(color: AppPalette.carbon, width: 1.5)
          : const BorderSide(color: AppPalette.line),
    );
    final support = AppTypography.support.copyWith(
      fontSize: 11.5,
      fontFeatures: AppTypography.tabularFigures,
    );

    return Material(
      color: needsAttention ? AppPalette.surfaceSunken : AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (orderLabel != null) ...[
                          Text(
                            orderLabel!,
                            style: AppTypography.micro.copyWith(
                              fontSize: 10.5,
                              letterSpacing: 10.5 * 0.07,
                              fontFeatures: AppTypography.tabularFigures,
                              color: AppPalette.ink55,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Text(
                          '${order.garmentType} · ${order.pieces} '
                          '${order.pieces == 1 ? 'pc' : 'pcs'}',
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 15 * -0.01,
                            color: AppPalette.carbon,
                          ),
                        ),
                        if (order.fabric?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 3),
                          Text(
                            order.fabric!,
                            style: AppTypography.support.copyWith(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupees(order.balance),
                        style: AppTypography.numberMd.copyWith(
                          fontSize: 15.5,
                          color: paid ? AppPalette.ink45 : AppPalette.carbon,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'of ${formatRupees(order.totalAmount)}',
                        style: support.copyWith(fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: AppDashedLine(),
              ),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OrderStatusBadge(order.status),
                        if (!_delivered)
                          Text(_dueText, style: support)
                        else if (paid)
                          const AppStatusBadge(label: 'Paid in full'),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (_delivered)
                    Text(
                      _dayMonth.format(order.deliveredAt ?? order.deliveryDate),
                      style: support,
                    )
                  else
                    Text(
                      'Open ›',
                      style: support.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppPalette.oliveInk,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';

/// An order stage as a badge: outlined while waiting, olive while being
/// made, carbon when ready for pickup, and muted once delivered.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge(this.status, {super.key});
  final String status;

  @override
  Widget build(BuildContext context) => switch (status) {
    OrderStatus.cutting || OrderStatus.stitching => AppStatusBadge(
      label: status,
      tone: AppBadgeTone.olive,
    ),
    OrderStatus.ready => AppStatusBadge(
      label: status,
      icon: Icons.check,
      tone: AppBadgeTone.strong,
    ),
    OrderStatus.delivered => AppStatusBadge(
      label: status,
      tone: AppBadgeTone.muted,
    ),
    _ => AppStatusBadge(label: status),
  };
}

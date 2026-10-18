import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_timing.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/order_actions.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_sheets.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/production_stepper.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/whatsapp_reminder.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

final _dayMonth = DateFormat('d MMM');
final _date = DateFormat('d MMM yyyy');
final _dateTime = DateFormat('d MMM, h:mm a');

/// One order: what it is, its money, its production stage and the actions
/// on it. Stage, payment and delivery are separate writes.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  /// A write is running; the actions wait for it.
  bool _busy = false;

  /// Deleted and on the way out.
  bool _deleted = false;

  OrdersNotifier get _orders => ref.read(ordersNotifierProvider.notifier);

  OrderActions get _actions => OrderActions(
    context,
    ref,
    onBusy: (busy) {
      if (mounted) setState(() => _busy = busy);
    },
  );

  Future<T> _run<T>(Future<T> Function() write) async {
    setState(() => _busy = true);
    try {
      return await write();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showFailure(Failure failure) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure is ValidationFailure
              ? failure.message
              : "Couldn't save the change. Please try again.",
        ),
      ),
    );
  }

  Future<void> _removePayment(Order order, Payment payment) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this payment?'),
        content: Text(
          '${formatRupees(payment.amount)} received on '
          '${_dateTime.format(payment.paidAt)} will be taken off this order '
          'and added back to its balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove payment'),
          ),
        ],
      ),
    );
    if (remove != true || !mounted) return;
    final failure = await _run(() => _orders.deletePayment(payment.id));
    if (!mounted) return;
    if (failure != null) return _showFailure(failure);
    showAppToast(
      context,
      message: 'Payment removed',
      detail: 'Balance now ${formatRupees(order.balance + payment.amount)}',
    );
  }

  Future<void> _delete(Order order, String orderLabel) async {
    final confirmed = await showDeleteOrderDialog(
      context,
      order: order,
      orderLabel: orderLabel,
    );
    if (!confirmed || !mounted) return;
    final failure = await _run(() => _orders.deleteOrder(order.id));
    if (!mounted) return;
    if (failure != null) return _showFailure(failure);
    setState(() => _deleted = true);
    showAppToast(context, message: '$orderLabel deleted');
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/orders');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_deleted) return const Scaffold(backgroundColor: AppPalette.white);
    final ordersAsync = ref.watch(ordersNotifierProvider);
    final orders = ordersAsync.valueOrNull;
    if (orders == null) {
      return Scaffold(
        backgroundColor: AppPalette.white,
        body: Center(
          child: ordersAsync.hasError
              ? const AppFeedback.error(message: "Couldn't open this order.")
              : const AppLoading(),
        ),
      );
    }
    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
    if (order == null) {
      return Scaffold(
        backgroundColor: AppPalette.white,
        appBar: AppBar(),
        body: const Center(
          child: AppFeedback(
            title: 'Order not found',
            message: 'This order is no longer saved on this device.',
            icon: Icons.receipt_long_outlined,
          ),
        ),
      );
    }

    Customer? customer;
    for (final saved
        in ref.watch(customersNotifierProvider).valueOrNull ??
            const <Customer>[]) {
      if (saved.id == order.customerId) customer = saved;
    }
    Measurement? measurement;
    for (final profile
        in ref.watch(measurementsNotifierProvider).valueOrNull ??
            const <Measurement>[]) {
      if (profile.id == order.measurementId) measurement = profile;
    }
    final settings =
        ref.watch(shopSettingsProvider).valueOrNull ?? const ShopSettings();
    final history =
        ref.watch(orderStatusHistoryProvider(order.id)).valueOrNull ??
        const <OrderStatusEvent>[];
    final payments =
        ref.watch(orderPaymentsProvider(order.id)).valueOrNull ??
        const <Payment>[];
    final today = ref.watch(clockProvider)();

    final customerName = customer?.name ?? 'Unknown customer';
    final label = order.orderNumber == null
        ? 'Order'
        : settings.orderLabel(order.orderNumber!);
    final subtitle = '$label · $customerName';

    return Scaffold(
      backgroundColor: AppPalette.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            order: order,
            customer: customer,
            orderLabel: label,
            today: today,
            onEdit: () => context.push('/orders/${order.id}/edit'),
            onDelete: () => _delete(order, label),
            onOpenCustomer: customer == null
                ? null
                : () => context.push('/customers/${order.customerId}'),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                AppSpacing.xl,
              ),
              children: [
                _MoneyRow(order: order),
                const SizedBox(height: AppSpacing.md),
                _InfoCard(
                  rows: [
                    _InfoRow(
                      'Fabric',
                      _orNone(order.fabric),
                      muted: order.fabric?.trim().isEmpty ?? true,
                    ),
                    _InfoRow('Pieces', '${order.pieces}'),
                    _InfoRow(
                      'Measurements',
                      measurement?.fitProfile ?? 'Not linked',
                      linked: measurement != null,
                      muted: measurement == null,
                      onTap: () => context.push(
                        Uri(
                          path: '/customers/${order.customerId}/measurements',
                          queryParameters: {
                            'garment':
                                measurement?.garmentType ?? order.garmentType,
                            'fit': ?measurement?.fitProfile,
                          },
                        ).toString(),
                      ),
                    ),
                    if (order.notes?.trim().isNotEmpty ?? false)
                      _InfoRow('Cutter note', order.notes!.trim()),
                    _InfoRow('Ordered', _date.format(order.createdAt)),
                    if (order.deliveredAt case final delivered?)
                      _InfoRow('Delivered', _date.format(delivered)),
                  ],
                ),
                const SizedBox(height: 20),
                const AppSectionRule('Production'),
                const SizedBox(height: 14),
                ProductionStepper(status: order.status),
                const SizedBox(height: 10),
                Text(
                  _productionCaption(order, history, today),
                  style: AppTypography.support.copyWith(
                    fontSize: 11.5,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
                const SizedBox(height: 22),
                const AppSectionRule('Payments'),
                const SizedBox(height: AppSpacing.md),
                if (payments.isEmpty)
                  Text(
                    'No payments recorded yet.',
                    style: AppTypography.support.copyWith(fontSize: 12.5),
                  )
                else
                  _InfoCard(
                    rows: [
                      for (final payment in payments)
                        _InfoRow(
                          [
                            _dayMonth.format(payment.paidAt),
                            payment.method.label,
                            if (payment.isAdvance) 'advance',
                          ].join(' · '),
                          formatRupees(payment.amount),
                          onTap: _busy
                              ? null
                              : () => _removePayment(order, payment),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          _ActionBar(
            order: order,
            busy: _busy,
            onChangeStatus: () => _actions.changeStatus(order),
            onRecordPayment: () =>
                _actions.recordPayment(order, subtitle: subtitle),
            onDeliver: () => _actions.deliver(
              order,
              customerName: customerName,
              subtitle: subtitle,
            ),
            onRemind: () => showReminderSheet(
              context,
              customerName: customerName,
              phone: customer?.phone,
              message: reminderMessage(
                order: order,
                customerName: customerName,
                orderLabel: order.orderNumber == null ? null : label,
                settings: settings,
                today: today,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _orNone(String? text) =>
      (text?.trim().isEmpty ?? true) ? 'Not noted' : text!.trim();

  /// When the order reached its stage and how long it has been in work.
  String _productionCaption(
    Order order,
    List<OrderStatusEvent> history,
    DateTime today,
  ) {
    DateTime? entered;
    for (final event in history.reversed) {
      if (event.status == order.status) {
        entered = event.changedAt;
        break;
      }
    }
    if (order.isDelivered) entered = order.deliveredAt ?? entered;
    final started = history.isEmpty ? order.createdAt : history.first.changedAt;
    final end = order.isDelivered ? (entered ?? today) : today;
    final days = DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(started.year, started.month, started.day)).inDays;
    final length = days <= 0
        ? (order.isDelivered ? 'same day' : 'started today')
        : '$days ${days == 1 ? 'day' : 'days'} in production';
    final stage = order.isDelivered ? 'Delivered' : '${order.status} since';
    return entered == null
        ? '${order.status} · $length'
        : '$stage ${_dateTime.format(entered)} · $length';
  }
}

enum _OrderAction { edit, delete }

class _Header extends StatelessWidget {
  const _Header({
    required this.order,
    required this.customer,
    required this.orderLabel,
    required this.today,
    required this.onEdit,
    required this.onDelete,
    required this.onOpenCustomer,
  });

  final Order order;
  final Customer? customer;
  final String orderLabel;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpenCustomer;

  String get _when {
    final date = _dayMonth.format(order.deliveryDate);
    if (order.isDelivered) {
      return 'Delivered ${_dayMonth.format(order.deliveredAt ?? order.deliveryDate)}';
    }
    final late = order.daysLate(today);
    if (late > 0) return 'Overdue $late ${late == 1 ? 'day' : 'days'} · $date';
    if (late == 0) return 'Deliver today · $date';
    if (late == -1) return 'Due tomorrow · $date';
    return 'Due $date · in ${-late} days';
  }

  @override
  Widget build(BuildContext context) {
    final phone = formatPhone(customer?.phone);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: AppPalette.carbon,
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              right: -20,
              bottom: 0,
              width: 140,
              child: AppTickPattern(color: Color(0x0FFFFFFF)),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        AppBoxedIconButton(
                          icon: Icons.chevron_left,
                          label: 'Back',
                          onCarbon: true,
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            orderLabel.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: AppTypography.micro.copyWith(
                              fontSize: 11.5,
                              letterSpacing: 11.5 * 0.09,
                              fontFeatures: AppTypography.tabularFigures,
                              color: AppPalette.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        PopupMenuButton<_OrderAction>(
                          tooltip: 'More',
                          icon: const Icon(Icons.more_vert, size: 20),
                          style: AppBoxedIconButton.styleOf(onCarbon: true),
                          onSelected: (action) => switch (action) {
                            _OrderAction.edit => onEdit(),
                            _OrderAction.delete => onDelete(),
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _OrderAction.edit,
                              child: Text('Edit order'),
                            ),
                            PopupMenuItem(
                              value: _OrderAction.delete,
                              child: Text('Delete order'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          Text(
                            order.garmentType,
                            style: AppTypography.title.copyWith(
                              fontSize: 24,
                              letterSpacing: 24 * -0.03,
                              color: AppPalette.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Semantics(
                            button: onOpenCustomer != null,
                            child: GestureDetector(
                              onTap: onOpenCustomer,
                              child: Text(
                                [
                                  customer?.name ?? 'Unknown customer',
                                  if (phone.isNotEmpty) phone,
                                ].join(' · '),
                                style: AppTypography.support.copyWith(
                                  fontFeatures: AppTypography.tabularFigures,
                                  color: AppPalette.white.withValues(
                                    alpha: 0.62,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _HeaderBadge(
                                order.status,
                                filled: true,
                                icon:
                                    order.status == OrderStatus.ready ||
                                        order.isDelivered
                                    ? Icons.check
                                    : null,
                              ),
                              _HeaderBadge(_when),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge(this.label, {this.filled = false, this.icon});
  final String label;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = filled ? AppPalette.carbon : AppPalette.white;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? AppPalette.white : null,
        borderRadius: BorderRadius.circular(6),
        border: filled
            ? null
            : Border.all(color: AppPalette.white.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: ink),
              const SizedBox(width: 5),
            ],
            Text(
              label.toUpperCase(),
              style: AppTypography.micro.copyWith(
                fontSize: 10,
                letterSpacing: 10 * 0.06,
                fontFeatures: AppTypography.tabularFigures,
                color: ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, double amount, {bool owed = false}) => Expanded(
      child: Container(
        color: owed ? AppPalette.carbon : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.micro.copyWith(
                fontSize: 9.5,
                letterSpacing: 9.5 * 0.08,
                color: owed
                    ? AppPalette.white.withValues(alpha: 0.6)
                    : AppPalette.ink55,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                formatRupees(amount),
                style: AppTypography.numberMd.copyWith(
                  color: owed ? AppPalette.white : AppPalette.carbon,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    const divider = VerticalDivider(width: 1, color: AppPalette.line);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppPalette.line),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            cell('TOTAL', order.totalAmount),
            divider,
            cell('PAID', order.paidAmount),
            divider,
            cell('OUTSTANDING', order.balance, owed: true),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  const _InfoRow(
    this.label,
    this.value, {
    this.linked = false,
    this.muted = false,
    this.onTap,
  });
  final String label;
  final String value;

  /// Nothing recorded; the value says so in a lighter ink.
  final bool muted;

  /// Marks the value as linked to a saved record.
  final bool linked;
  final VoidCallback? onTap;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.support.copyWith(color: AppPalette.ink55);
    final valueStyle = AppTypography.body.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w600,
      fontFeatures: AppTypography.tabularFigures,
      color: AppPalette.carbon,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppPalette.line),
    );
    return Material(
      color: AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: AppDashedLine(),
              ),
            InkWell(
              onTap: row.onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppSizing.minHitTarget,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(row.label, style: labelStyle)),
                        const SizedBox(width: AppSpacing.md),
                        ConstrainedBox(
                          // Values sit at the right edge, wrapping before
                          // they crowd the label.
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth * 0.62,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  row.value,
                                  textAlign: TextAlign.right,
                                  style: row.muted
                                      ? valueStyle.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppPalette.ink55,
                                        )
                                      : valueStyle,
                                ),
                              ),
                              if (row.linked) ...[
                                const SizedBox(width: 7),
                                const AppStatusBadge(
                                  label: 'Linked',
                                  tone: AppBadgeTone.olive,
                                ),
                              ],
                              if (row.onTap != null) ...[
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppPalette.ink45,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.order,
    required this.busy,
    required this.onChangeStatus,
    required this.onRecordPayment,
    required this.onDeliver,
    required this.onRemind,
  });

  final Order order;
  final bool busy;
  final VoidCallback onChangeStatus;
  final VoidCallback onRecordPayment;
  final VoidCallback onDeliver;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final owed = order.balance > 0;
    VoidCallback? unlessBusy(VoidCallback action) => busy ? null : action;
    final recordPayment = AppButton(
      label: 'Record Payment',
      onPressed: owed ? unlessBusy(onRecordPayment) : null,
    );
    final remind = AppButton(
      label: 'Reminder',
      icon: Icons.chat_bubble_outline,
      variant: AppButtonVariant.outlined,
      onPressed: unlessBusy(onRemind),
    );

    final List<List<Widget>> rows;
    if (!order.isDelivered) {
      rows = [
        [
          AppButton(
            label: 'Change Status',
            variant: AppButtonVariant.outlined,
            onPressed: unlessBusy(onChangeStatus),
          ),
          recordPayment,
        ],
        [
          AppButton(
            label: 'Mark Delivered',
            icon: Icons.check,
            variant: AppButtonVariant.olive,
            onPressed: unlessBusy(onDeliver),
          ),
          remind,
        ],
      ];
    } else if (owed) {
      rows = [
        [remind, recordPayment],
      ];
    } else {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppPalette.white,
        border: Border(top: BorderSide(color: AppPalette.line)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            14,
            AppSpacing.screenPadding,
            0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, row) in rows.indexed) ...[
                if (index > 0) const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: row[0]),
                    const SizedBox(width: 10),
                    Expanded(child: row[1]),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

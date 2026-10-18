import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_avatar.dart';
import 'package:tailor_khata/features/dashboard/domain/entities/money_summary.dart';
import 'package:tailor_khata/features/dashboard/presentation/widgets/money_card.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_timing.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/order_actions.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_status_badge.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

/// Home: the month's money, the work in the shop and today's deliveries.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  /// Deliveries listed before "View all".
  static const _shownDeliveries = 5;

  /// The first of the month the revenue card shows; null for this month.
  DateTime? _month;

  OrderActions get _actions => OrderActions(context, ref);

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersNotifierProvider);
    final orders = ordersAsync.valueOrNull;
    final today = ref.watch(clockProvider)();
    final settings =
        ref.watch(shopSettingsProvider).valueOrNull ?? const ShopSettings();

    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        bottom: false,
        child: orders == null
            ? Center(
                child: ordersAsync.hasError
                    ? AppFeedback.error(
                        message: "Couldn't open your orders.",
                        actionLabel: 'Try again',
                        onAction: () => ref
                            .read(ordersNotifierProvider.notifier)
                            .loadOrders(),
                      )
                    : const AppLoading(),
              )
            : _buildHome(orders, today, settings),
      ),
    );
  }

  Widget _buildHome(List<Order> orders, DateTime today, ShopSettings settings) {
    final payments =
        ref.watch(paymentsProvider).valueOrNull ?? const <Payment>[];
    final customers = {
      for (final customer
          in ref.watch(customersNotifierProvider).valueOrNull ??
              const <Customer>[])
        customer.id: customer,
    };
    final thisMonth = DateTime(today.year, today.month);
    final month = _month ?? thisMonth;
    final summary = MoneySummary.of(
      Period.month(month.year, month.month),
      orders,
      payments,
    );
    final owed = totalOutstanding(orders);
    final inWork = orders
        .where((o) => !o.isDelivered && o.status != OrderStatus.ready)
        .length;
    final dueToday = [
      for (final order in orders)
        if (order.isDueToday(today)) order,
    ]..sort(compareForWorklist);
    final overdue = [
      for (final order in orders)
        if (order.isOverdue(today)) order,
    ];
    final share = summary.collectedShare;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      children: [
        _Header(today: today, settings: settings),
        const SizedBox(height: 14),
        MoneyCard(
          prominent: true,
          label: month == thisMonth
              ? "This month's revenue"
              : 'Revenue · ${_monthName(month, today)}',
          amount: summary.billed,
          onTap: () => context.push('/home/revenue'),
          trailing: _MonthPicker(
            months: _months(orders, payments, thisMonth),
            selected: month,
            today: today,
            onSelected: (picked) =>
                setState(() => _month = picked == thisMonth ? null : picked),
          ),
          tiles: [
            MoneyTile(
              label: 'Outstanding',
              amount: owed.amount,
              caption: owed.orders == 0
                  ? 'nothing owed'
                  : 'across ${owed.orders} '
                        '${owed.orders == 1 ? 'order' : 'orders'}',
            ),
            MoneyTile(
              label: 'Collected',
              amount: summary.collected,
              caption: share == null
                  ? 'nothing billed yet'
                  : '${(share * 100).round()}% of billed',
            ),
          ],
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'In progress',
                  value: inWork,
                  caption: inWork == 1 ? 'order in work' : 'orders in work',
                  onTap: () => context.go('/orders'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_today_outlined,
                  label: 'Due today',
                  value: dueToday.length,
                  caption: [
                    dueToday.length == 1 ? 'delivery' : 'deliveries',
                    if (overdue.isNotEmpty) '${overdue.length} overdue',
                  ].join(' · '),
                  onTap: () => context.go('/orders?filter=today'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: AppButton(
                label: 'New Order',
                icon: Icons.add,
                onPressed: () => context.push('/orders/new'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 4,
              child: AppButton(
                label: 'Customer',
                icon: Icons.person_add_alt_1_outlined,
                variant: AppButtonVariant.outlined,
                onPressed: () => context.push('/customers/new'),
              ),
            ),
          ],
        ),
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _OverdueLink(orders: overdue),
        ],
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Expanded(child: AppSectionLabel("Today's deliveries")),
            TextButton(
              onPressed: () => context.go('/orders?filter=today'),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.oliveInk,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                textStyle: AppTypography.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('View all ›'),
            ),
          ],
        ),
        if (dueToday.isEmpty)
          AppDashedBox(
            padding: const EdgeInsets.all(18),
            child: Text(
              orders.isEmpty
                  ? 'No orders yet. New orders due today will be listed here.'
                  : 'Nothing is due for delivery today.',
              textAlign: TextAlign.center,
              style: AppTypography.support.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          )
        else
          _Deliveries(
            orders: dueToday.take(_shownDeliveries).toList(),
            customers: customers,
            today: today,
            onOpen: (order) => context.push('/orders/${order.id}'),
            onDeliver: (order) {
              final name = customers[order.customerId]?.name ?? 'Customer';
              _actions.deliver(
                order,
                customerName: name,
                subtitle: _subtitle(order, name, settings),
              );
            },
            onUpdate: (order) => _actions.changeStatus(order),
          ),
      ],
    );
  }

  String _subtitle(Order order, String customerName, ShopSettings settings) {
    final number = order.orderNumber;
    return number == null
        ? customerName
        : '${settings.orderLabel(number)} · $customerName';
  }

  /// Months with orders or payments, newest first, up to a year back.
  List<DateTime> _months(
    List<Order> orders,
    List<Payment> payments,
    DateTime thisMonth,
  ) {
    var earliest = thisMonth;
    for (final time in [
      for (final order in orders) order.createdAt,
      for (final payment in payments) payment.paidAt,
    ]) {
      final month = DateTime(time.year, time.month);
      if (month.isBefore(earliest)) earliest = month;
    }
    return [
      for (var back = 0; back < 12; back++)
        if (!DateTime(
          thisMonth.year,
          thisMonth.month - back,
        ).isBefore(earliest))
          DateTime(thisMonth.year, thisMonth.month - back),
    ];
  }
}

/// `September`, or `December 2025` outside the current year.
String _monthName(DateTime month, DateTime today) =>
    DateFormat(month.year == today.year ? 'MMMM' : 'MMMM yyyy').format(month);

class _Header extends StatelessWidget {
  const _Header({required this.today, required this.settings});
  final DateTime today;
  final ShopSettings settings;

  @override
  Widget build(BuildContext context) {
    final shop = settings.shopName.trim();
    final owner = settings.ownerName.trim();
    final initials = owner.isNotEmpty
        ? customerInitials(owner)
        : shop.isNotEmpty
        ? customerInitials(shop)
        : 'TK';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM').format(today),
                style: AppTypography.support.copyWith(color: AppPalette.ink55),
              ),
              const SizedBox(height: 3),
              Text(
                shop.isEmpty ? 'Tailor Khata' : shop,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.screenTitle.copyWith(
                  height: 1.2,
                  color: AppPalette.carbon,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          button: true,
          label: 'Shop settings',
          child: Material(
            color: const Color.fromRGBO(124, 128, 112, 0.16),
            shape: const CircleBorder(
              side: BorderSide(color: Color.fromRGBO(124, 128, 112, 0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/settings'),
              child: SizedBox.square(
                dimension: AppSizing.minHitTarget,
                child: Center(
                  child: ExcludeSemantics(
                    child: Text(
                      initials,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3C4038),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.months,
    required this.selected,
    required this.today,
    required this.onSelected,
  });

  final List<DateTime> months;
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<DateTime>(
    tooltip: 'Choose month',
    initialValue: selected,
    onSelected: onSelected,
    itemBuilder: (context) => [
      for (final month in months)
        PopupMenuItem(value: month, child: Text(_monthName(month, today))),
    ],
    child: ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizing.minHitTarget),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.26),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat(
                  selected.year == today.year ? 'MMM' : 'MMM yyyy',
                ).format(selected),
                style: AppTypography.micro.copyWith(
                  fontSize: 10.5,
                  color: const Color.fromRGBO(255, 255, 255, 0.8),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: Color.fromRGBO(255, 255, 255, 0.8),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppPalette.ink70),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: AppTypography.micro.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 10.5 * 0.07,
                  color: AppPalette.ink70,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$value',
          style: AppTypography.numberLg.copyWith(
            fontSize: 26,
            letterSpacing: 26 * -0.02,
            color: AppPalette.carbon,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          caption,
          style: AppTypography.support.copyWith(
            fontSize: 11.5,
            color: AppPalette.ink55,
          ),
        ),
      ],
    ),
  );
}

class _OverdueLink extends StatelessWidget {
  const _OverdueLink({required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final owed = totalOutstanding(orders).amount;
    final count = orders.length;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: AppPalette.carbon, width: 1.5),
    );
    return Material(
      color: AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/orders?filter=overdue'),
        customBorder: shape,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: AppPalette.carbon,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? '1 order past its delivery date'
                          : '$count orders past their delivery date',
                      style: AppTypography.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.carbon,
                      ),
                    ),
                    if (owed > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${formatRupees(owed)} outstanding across '
                        '${count == 1 ? 'it' : 'them'}',
                        style: AppTypography.support.copyWith(
                          fontSize: 11.5,
                          fontFeatures: AppTypography.tabularFigures,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppPalette.ink45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Deliveries extends StatelessWidget {
  const _Deliveries({
    required this.orders,
    required this.customers,
    required this.today,
    required this.onOpen,
    required this.onDeliver,
    required this.onUpdate,
  });

  final List<Order> orders;
  final Map<String, Customer> customers;
  final DateTime today;
  final ValueChanged<Order> onOpen;
  final ValueChanged<Order> onDeliver;
  final ValueChanged<Order> onUpdate;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppPalette.line),
    );
    return Material(
      color: AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, order) in orders.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: AppDashedLine(),
              ),
            _DeliveryRow(
              order: order,
              customerName:
                  customers[order.customerId]?.name ?? 'Unknown customer',
              today: today,
              onOpen: () => onOpen(order),
              onAction: order.status == OrderStatus.ready
                  ? () => onDeliver(order)
                  : () => onUpdate(order),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  const _DeliveryRow({
    required this.order,
    required this.customerName,
    required this.today,
    required this.onOpen,
    required this.onAction,
  });

  final Order order;
  final String customerName;
  final DateTime today;
  final VoidCallback onOpen;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final ready = order.status == OrderStatus.ready;
    final paid = order.balance <= 0;
    final support = AppTypography.support.copyWith(
      fontSize: 11.5,
      fontFeatures: AppTypography.tabularFigures,
      color: AppPalette.ink55,
    );
    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
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
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 14.5 * -0.01,
                      color: AppPalette.carbon,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.garmentType} · ${order.pieces} '
                    '${order.pieces == 1 ? 'pc' : 'pcs'}',
                    style: AppTypography.support.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OrderStatusBadge(order.status),
                      Text(
                        'Today, ${DateFormat('d MMM').format(today)}',
                        style: support,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  paid ? 'Paid' : formatRupees(order.balance),
                  style: AppTypography.numberMd.copyWith(
                    fontSize: 14.5,
                    color: paid ? AppPalette.ink45 : AppPalette.carbon,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  paid ? 'in full' : 'outstanding',
                  style: support.copyWith(fontSize: 10.5),
                ),
                const SizedBox(height: 7),
                OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    fixedSize: const Size.fromHeight(34),
                    tapTargetSize: MaterialTapTargetSize.padded,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    backgroundColor: ready
                        ? const Color.fromRGBO(124, 128, 112, 0.16)
                        : AppPalette.white,
                    foregroundColor: ready
                        ? AppPalette.oliveInk
                        : AppPalette.carbon,
                    side: BorderSide(
                      color: ready
                          ? AppPalette.oliveBorder
                          : AppPalette.lineStrong,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    textStyle: AppTypography.body.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(ready ? 'Deliver' : 'Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

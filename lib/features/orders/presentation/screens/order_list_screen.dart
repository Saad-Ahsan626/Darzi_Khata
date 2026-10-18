import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_timing.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_list_card.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/whatsapp_reminder.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

enum _Filter {
  all('All'),
  today('Today'),
  upcoming('Upcoming'),
  overdue('Overdue');

  const _Filter(this.label);
  final String label;

  /// The filter named in a link such as `/orders?filter=today`.
  static _Filter named(String? name) =>
      values.where((filter) => filter.name == name).firstOrNull ?? all;

  bool includes(Order order, DateTime today) => switch (this) {
    _Filter.all => true,
    _Filter.today => order.isDueToday(today),
    _Filter.upcoming => order.isUpcoming(today),
    _Filter.overdue => order.isOverdue(today),
  };
}

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key, this.initialFilter});

  /// `today`, `upcoming` or `overdue`; all orders otherwise.
  final String? initialFilter;

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  late _Filter _filter = _Filter.named(widget.initialFilter);

  @override
  void didUpdateWidget(OrderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opened again from a link or the navigation bar.
    if (widget.initialFilter != oldWidget.initialFilter) {
      _filter = _Filter.named(widget.initialFilter);
    }
  }

  void _newOrder() => context.push('/orders/new');

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersNotifierProvider);
    final orders = ordersAsync.valueOrNull;
    final today = ref.watch(clockProvider)();
    final overdue = orders?.where((order) => order.isOverdue(today)).length;

    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orders',
                          style: AppTypography.screenTitle.copyWith(
                            color: AppPalette.carbon,
                          ),
                        ),
                        if (orders != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            _summary(orders),
                            style: AppTypography.support.copyWith(
                              fontSize: 12.5,
                              fontFeatures: AppTypography.tabularFigures,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Tooltip(
                    message: 'New order',
                    child: AppButton(
                      label: 'New',
                      icon: Icons.add,
                      expand: false,
                      onPressed: _newOrder,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                18,
                AppSpacing.screenPadding,
                0,
              ),
              child: Row(
                children: [
                  for (final filter in _Filter.values) ...[
                    if (filter != _Filter.all) const SizedBox(width: 7),
                    _FilterChip(
                      label: filter.label,
                      count: switch (filter) {
                        _Filter.all => orders?.length,
                        _Filter.overdue => overdue,
                        _ => null,
                      },
                      selected: filter == _filter,
                      // Late orders call for attention from every filter.
                      emphasised:
                          filter == _Filter.overdue && (overdue ?? 0) > 0,
                      onTap: () => setState(() => _filter = filter),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ordersAsync.when(
                skipLoadingOnRefresh: true,
                loading: () => const Center(child: AppLoading()),
                error: (error, stack) => Center(
                  child: AppFeedback.error(
                    message: "Couldn't open your orders.",
                    actionLabel: 'Try again',
                    onAction: () =>
                        ref.read(ordersNotifierProvider.notifier).loadOrders(),
                  ),
                ),
                data: (orders) => _buildList(orders, today),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _summary(List<Order> orders) {
    final open = orders.where((order) => !order.isDelivered).length;
    final outstanding = orders.fold<double>(
      0,
      (sum, order) => sum + order.balance,
    );
    return [
      if (orders.isEmpty)
        'Nothing saved yet'
      else
        open == 0 ? 'No open orders' : '$open open',
      if (outstanding > 0) '${formatRupees(outstanding)} outstanding',
    ].join(' · ');
  }

  Widget _buildList(List<Order> orders, DateTime today) {
    if (orders.isEmpty) {
      return _Empty(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        message:
            'Create the first order for a customer and it will be '
            'tracked here until delivery.',
        actionLabel: 'New order',
        onAction: _newOrder,
      );
    }
    final shown = [
      for (final order in orders)
        if (_filter.includes(order, today)) order,
    ]..sort(compareForWorklist);

    final customers = {
      for (final customer
          in ref.watch(customersNotifierProvider).valueOrNull ??
              const <Customer>[])
        customer.id: customer,
    };
    final settings =
        ref.watch(shopSettingsProvider).valueOrNull ?? const ShopSettings();

    Widget card(Order order) {
      final customer = customers[order.customerId];
      final label = order.orderNumber == null
          ? null
          : settings.orderLabel(order.orderNumber!);
      return OrderListCard(
        order: order,
        customerName: customer?.name ?? 'Unknown customer',
        orderLabel: label,
        today: today,
        onTap: () => context.push('/orders/${order.id}'),
        onRemind: _filter == _Filter.overdue && customer != null
            ? () => showReminderSheet(
                context,
                customerName: customer.name,
                phone: customer.phone,
                message: reminderMessage(
                  order: order,
                  customerName: customer.name,
                  orderLabel: label,
                  settings: settings,
                  today: today,
                ),
              )
            : null,
      );
    }

    final children = <Widget>[
      if (_filter == _Filter.overdue && shown.isNotEmpty)
        _OverdueBanner(orders: shown),
    ];
    var deliveredHeading = false;
    for (final order in shown) {
      if (order.isDelivered && !deliveredHeading) {
        deliveredHeading = true;
        children.add(
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.sm),
            child: AppSectionLabel('Delivered'),
          ),
        );
      }
      children.add(card(order));
    }
    if (shown.isEmpty) {
      children.add(switch (_filter) {
        _Filter.overdue => const _Empty(
          icon: Icons.check,
          title: 'Nothing overdue',
          message: 'Every order is on or ahead of its delivery date.',
        ),
        _Filter.today => const _Empty(
          icon: Icons.today_outlined,
          title: 'Nothing due today',
          message: 'Orders to deliver today will be listed here.',
        ),
        _ => const _Empty(
          icon: Icons.event_outlined,
          title: 'Nothing upcoming',
          message: 'Orders due after today will be listed here.',
        ),
      });
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      itemCount: children.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => children[index],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.emphasised,
    required this.onTap,
  });

  final String label;
  final int? count;
  final bool selected;
  final bool emphasised;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strong = selected || emphasised;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizing.minHitTarget),
          fixedSize: const Size.fromHeight(38),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          backgroundColor: selected ? AppPalette.carbon : AppPalette.white,
          foregroundColor: selected ? AppPalette.white : AppPalette.carbon,
          side: BorderSide(
            color: strong ? AppPalette.carbon : AppPalette.lineStrong,
            width: emphasised && !selected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: AppTypography.body.copyWith(
            fontSize: 12.5,
            fontWeight: strong ? FontWeight.w600 : FontWeight.w500,
          ),
          animationDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.selection,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count != null && (count! > 0 || selected)) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  fontFeatures: AppTypography.tabularFigures,
                  color: selected
                      ? AppPalette.white.withValues(alpha: 0.62)
                      : AppPalette.carbon,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final outstanding = orders.fold<double>(
      0,
      (sum, order) => sum + order.balance,
    );
    final count = orders.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppPalette.carbon, width: 1.5),
      ),
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
                const SizedBox(height: 2),
                Text(
                  outstanding > 0
                      ? '${formatRupees(outstanding)} outstanding across '
                            '${count == 1 ? 'it' : 'them'}'
                      : 'Nothing is owed on ${count == 1 ? 'it' : 'them'}',
                  style: AppTypography.support.copyWith(
                    fontSize: 11.5,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final box = AppDashedBox(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppPalette.oliveFill10,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color.fromRGBO(124, 128, 112, 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 21, color: AppPalette.oliveInk),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 15.5 * -0.01,
              color: AppPalette.carbon,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.support.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: actionLabel!,
              icon: Icons.add,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
    // With no orders at all it is the whole list, so it scrolls by itself.
    return onAction == null
        ? box
        : ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [box],
          );
  }
}

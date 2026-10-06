import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer_activity.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customer_activity_provider.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_avatar.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_dialogs.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_order_card.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/measurement_profile_card.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  /// Orders shown before the rest are folded behind "Show earlier orders".
  static const _recentOrders = 3;

  late TabController _tabController;
  bool _showAllOrders = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      // The header is compact on the order history tab.
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _delete(Customer customer, CustomerActivity activity) async {
    final confirmed = await showDeleteCustomerDialog(
      context,
      customer: customer,
      activity: activity,
    );
    if (!confirmed || !mounted) return;

    final failure = await ref
        .read(customersNotifierProvider.notifier)
        .deleteCustomer(customer.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (failure != null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Couldn't delete the customer. Please try again."),
        ),
      );
      return;
    }
    final photo = customer.imagePath;
    if (photo != null && photo.isNotEmpty) {
      final file = await customerPhotoFile(photo);
      if (await file.exists()) await file.delete();
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('${customer.name} deleted')),
    );
    context.go('/customers');
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);

    return customersAsync.when(
      loading: () => const Scaffold(body: Center(child: AppLoading())),
      error: (e, s) => const Scaffold(
        body: Center(
          child: AppFeedback.error(message: "Couldn't open this customer."),
        ),
      ),
      data: (customers) {
        final cList = customers
            .where((c) => c.id == widget.customerId)
            .toList();
        if (cList.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: AppFeedback(
                title: 'Customer not found',
                message: 'This customer is no longer saved on this device.',
                icon: Icons.person_off_outlined,
              ),
            ),
          );
        }
        final customer = cList.first;
        final activity =
            ref.watch(customerActivityProvider)[customer.id] ??
            const CustomerActivity();
        final measurements = [
          for (final measurement
              in ref.watch(measurementsNotifierProvider).valueOrNull ??
                  const <Measurement>[])
            if (measurement.customerId == customer.id) measurement,
        ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final orders = _inHistoryOrder([
          for (final order
              in ref.watch(ordersNotifierProvider).valueOrNull ?? const <Order>[])
            if (order.customerId == customer.id) order,
        ]);

        return Scaffold(
          backgroundColor: AppPalette.white,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                customer: customer,
                activity: activity,
                compact: _tabController.index == 1,
                onEdit: () => context.push(
                  '/customers/${customer.id}/edit',
                  extra: customer,
                ),
                onDelete: () => _delete(customer, activity),
                onAddMeasurements: () =>
                    context.push('/customers/${customer.id}/measurements'),
                onCreateOrder: () =>
                    context.push('/orders/new?customerId=${customer.id}'),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: const EdgeInsets.symmetric(horizontal: 7),
                labelPadding: const EdgeInsets.symmetric(horizontal: 13),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2,
                labelStyle: AppTypography.body.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTypography.body.copyWith(
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Measurements'),
                  Tab(text: 'Order History'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMeasurements(customer, measurements),
                    _buildOrders(customer, activity, orders),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Open orders first, soonest delivery at the top, then delivered orders
  /// from the most recent back.
  List<Order> _inHistoryOrder(List<Order> orders) {
    bool delivered(Order order) => order.status == OrderStatus.delivered;
    return orders..sort((a, b) {
      if (delivered(a) != delivered(b)) return delivered(a) ? 1 : -1;
      return delivered(a)
          ? (b.deliveredAt ?? b.createdAt).compareTo(
              a.deliveredAt ?? a.createdAt,
            )
          : a.deliveryDate.compareTo(b.deliveryDate);
    });
  }

  Widget _buildMeasurements(Customer customer, List<Measurement> measurements) {
    void open() => context.push('/customers/${customer.id}/measurements');
    if (measurements.isEmpty) {
      return _EmptyTab(
        title: 'No measurements yet',
        message:
            'Take them once and they are ready for every order '
            '${customer.name} places.',
        actionLabel: 'Add Measurements',
        onAction: open,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        18,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      itemCount: measurements.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => MeasurementProfileCard(
        measurement: measurements[index],
        onTap: open,
      ),
    );
  }

  Widget _buildOrders(
    Customer customer,
    CustomerActivity activity,
    List<Order> orders,
  ) {
    if (orders.isEmpty) {
      return _EmptyTab(
        title: 'No orders yet',
        message: 'Orders for ${customer.name} will be listed here.',
        actionLabel: 'Create Order',
        onAction: () => context.push('/orders/new?customerId=${customer.id}'),
      );
    }
    final settings =
        ref.watch(shopSettingsProvider).valueOrNull ?? const ShopSettings();
    final today = ref.watch(clockProvider)();
    final shown = _showAllOrders ? orders : orders.take(_recentOrders);
    final hidden = orders.length - shown.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      children: [
        AppSectionLabel(
          [
            '${orders.length} ${orders.length == 1 ? 'order' : 'orders'}',
            if (activity.outstanding > 0)
              '${formatRupees(activity.outstanding)} outstanding',
          ].join(' · '),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final order in shown) ...[
          CustomerOrderCard(
            order: order,
            orderLabel: order.orderNumber == null
                ? null
                : settings.orderLabel(order.orderNumber!),
            today: today,
            onTap: () => context.push('/orders/${order.id}'),
          ),
          const SizedBox(height: 10),
        ],
        if (hidden > 0)
          AppButton(
            label:
                'Show $hidden earlier ${hidden == 1 ? 'order' : 'orders'}',
            variant: AppButtonVariant.outlined,
            onPressed: () => setState(() => _showAllOrders = true),
          ),
      ],
    );
  }
}

enum _CustomerAction { delete }

class _Header extends StatelessWidget {
  const _Header({
    required this.customer,
    required this.activity,
    required this.compact,
    required this.onEdit,
    required this.onDelete,
    required this.onAddMeasurements,
    required this.onCreateOrder,
  });

  final Customer customer;
  final CustomerActivity activity;

  /// Only the back button, avatar, name and phone.
  final bool compact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddMeasurements;
  final VoidCallback onCreateOrder;

  static const _muted = AppPalette.onCarbonMuted;

  @override
  Widget build(BuildContext context) {
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
              width: 120,
              child: AppTickPattern(color: Color(0x12FFFFFF)),
            ),
            SafeArea(
              bottom: false,
              child: AnimatedSize(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppMotion.sheet,
                curve: AppMotion.curve,
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.screenPadding,
                    compact ? 18 : 20,
                  ),
                  child: compact ? _buildCompact(context) : _buildFull(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) => AppBoxedIconButton(
    icon: Icons.chevron_left,
    label: 'Back',
    onCarbon: true,
    onPressed: () => context.pop(),
  );

  String get _phone {
    final phone = formatPhone(customer.phone);
    return phone.isEmpty ? 'No phone number' : phone;
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      children: [
        _backButton(context),
        const SizedBox(width: 10),
        CustomerAvatar(
          customer: customer,
          size: 44,
          tone: CustomerAvatarTone.onCarbon,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer.name,
                style: AppTypography.title.copyWith(
                  fontSize: 18,
                  letterSpacing: 18 * -0.02,
                  color: AppPalette.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _phone,
                style: AppTypography.support.copyWith(
                  fontSize: 12,
                  fontFeatures: AppTypography.tabularFigures,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFull(BuildContext context) {
    final address = customer.address ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _backButton(context),
            const Spacer(),
            AppBoxedIconButton(
              icon: Icons.edit_outlined,
              label: 'Edit customer',
              onCarbon: true,
              onPressed: onEdit,
            ),
            PopupMenuButton<_CustomerAction>(
              tooltip: 'More',
              icon: const Icon(Icons.more_vert, size: 20),
              style: AppBoxedIconButton.styleOf(onCarbon: true),
              onSelected: (action) => onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _CustomerAction.delete,
                  child: Text('Delete customer'),
                ),
              ],
            ),
          ],
        ),
        Padding(
          // The buttons above sit in a touch target wider than they look.
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  CustomerAvatar(
                    customer: customer,
                    size: 60,
                    tone: CustomerAvatarTone.onCarbon,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: AppTypography.title.copyWith(
                            color: AppPalette.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [_phone, if (address.isNotEmpty) address].join(' · '),
                          style: AppTypography.support.copyWith(
                            fontFeatures: AppTypography.tabularFigures,
                            color: _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onAddMeasurements,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Measurements'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPalette.white,
                        foregroundColor: AppPalette.carbon,
                        overlayColor: AppPalette.carbon,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.md,
                        ),
                        textStyle: _buttonText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCreateOrder,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppPalette.glassOnCarbon,
                        foregroundColor: AppPalette.white,
                        overlayColor: AppPalette.white,
                        side: const BorderSide(color: AppPalette.glassBorder),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.md,
                        ),
                        textStyle: _buttonText,
                      ),
                      child: const Text('Create Order'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              IntrinsicHeight(
                child: Row(
                  children: [
                    Flexible(child: _Stat('${activity.orderCount}', 'orders')),
                    const _StatDivider(),
                    Flexible(
                      child: _Stat(
                        formatRupees(activity.outstanding),
                        'outstanding',
                      ),
                    ),
                    const _StatDivider(),
                    Flexible(
                      child: _Stat(
                        DateFormat('MMM yyyy').format(customer.createdAt),
                        'customer since',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static final _buttonText = AppTypography.body.copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
  );
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: AppTypography.numberMd.copyWith(
          fontSize: 16,
          color: AppPalette.white,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: AppTypography.micro.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: AppPalette.onCarbonMuted,
        ),
      ),
    ],
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 18),
    child: VerticalDivider(width: 1, color: AppPalette.glassBorder),
  );
}

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.screenPadding),
    child: AppDashedBox(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: AppPalette.carbon,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.support.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: actionLabel,
            variant: AppButtonVariant.outlined,
            onPressed: onAction,
          ),
        ],
      ),
    ),
  );
}

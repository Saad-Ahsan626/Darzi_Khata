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
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/dashboard/domain/entities/money_summary.dart';
import 'package:tailor_khata/features/dashboard/presentation/widgets/money_card.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_sheets.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

enum _Range {
  thisMonth('This month'),
  lastMonth('Last month'),
  year('Year'),
  custom('Custom');

  const _Range(this.label);
  final String label;
}

/// `1–4 October`, `September`, `12 Sep – 3 Oct` or, across years,
/// `12 Dec 2025 – 3 Jan 2026`.
String periodLabel(Period period) {
  final first = period.start;
  final last = period.last;
  final wholeMonth =
      first.day == 1 &&
      DateTime(last.year, last.month, last.day + 1).day == 1 &&
      first.month == last.month &&
      first.year == last.year;
  if (wholeMonth) return DateFormat('MMMM').format(first);
  if (first == last) return DateFormat('d MMMM').format(first);
  if (first.year != last.year) {
    final format = DateFormat('d MMM yyyy');
    return '${format.format(first)} – ${format.format(last)}';
  }
  if (first.month == last.month) {
    return '${first.day}–${DateFormat('d MMMM').format(last)}';
  }
  final format = DateFormat('d MMM');
  return '${format.format(first)} – ${format.format(last)}';
}

/// Rupees in short form for chart labels: `850`, `1.5k`, `96k`, `1.2M`.
String compactRupees(num amount) {
  String trim(String value) =>
      value.endsWith('.0') ? value.substring(0, value.length - 2) : value;
  if (amount >= 1000000) {
    return '${trim((amount / 1000000).toStringAsFixed(1))}M';
  }
  if (amount >= 10000) return '${(amount / 1000).round()}k';
  if (amount >= 1000) return '${trim((amount / 1000).toStringAsFixed(1))}k';
  return amount.round().toString();
}

/// Money over a period: what was collected, billed and is still owed, the
/// last six months side by side and the payments behind the figure.
class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> {
  /// Payments listed before "Show all".
  static const _shownPayments = 5;

  _Range _range = _Range.thisMonth;
  DateTimeRange? _custom;
  bool _showAllPayments = false;

  Period _period(DateTime today) => switch (_range) {
    _Range.thisMonth => Period.monthToDate(today),
    _Range.lastMonth => Period.month(today.year, today.month - 1),
    _Range.year => Period.yearToDate(today),
    _Range.custom => Period.days(_custom!.start, _custom!.end),
  };

  Future<void> _choose(_Range range, DateTime today) async {
    if (range != _Range.custom) {
      setState(() {
        _range = range;
        _showAllPayments = false;
      });
      return;
    }
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: today,
      initialDateRange:
          _custom ??
          DateTimeRange(
            start: DateTime(today.year, today.month, today.day - 29),
            end: today,
          ),
      helpText: 'Choose dates',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _custom = picked;
      _range = _Range.custom;
      _showAllPayments = false;
    });
  }

  Future<void> _copy(
    List<Payment> payments,
    Map<String, Order> orders,
    Map<String, Customer> customers,
    ShopSettings settings,
  ) async {
    String cell(String value) => value.contains(RegExp(r'[",\n]'))
        ? '"${value.replaceAll('"', '""')}"'
        : value;
    final timestamp = DateFormat('yyyy-MM-dd HH:mm');
    final lines = [
      'Date,Order,Customer,Method,Advance,Amount',
      for (final payment in payments.reversed)
        [
          timestamp.format(payment.paidAt),
          _label(orders[payment.orderId], settings),
          customers[orders[payment.orderId]?.customerId]?.name ?? '',
          payment.method.label,
          payment.isAdvance ? 'yes' : 'no',
          payment.amount.toStringAsFixed(
            payment.amount == payment.amount.roundToDouble() ? 0 : 2,
          ),
        ].map(cell).join(','),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    showAppToast(
      context,
      message:
          'Copied ${payments.length} '
          '${payments.length == 1 ? 'payment' : 'payments'}',
      detail: 'As CSV, ready to paste into a spreadsheet',
    );
  }

  static String _label(Order? order, ShopSettings settings) =>
      order?.orderNumber == null
      ? ''
      : settings.orderLabel(order!.orderNumber!);

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(clockProvider)();
    final orders =
        ref.watch(ordersNotifierProvider).valueOrNull ?? const <Order>[];
    final paymentsAsync = ref.watch(paymentsProvider);
    final payments = paymentsAsync.valueOrNull ?? const <Payment>[];
    final customers = {
      for (final customer
          in ref.watch(customersNotifierProvider).valueOrNull ??
              const <Customer>[])
        customer.id: customer,
    };
    final settings =
        ref.watch(shopSettingsProvider).valueOrNull ?? const ShopSettings();
    final byId = {for (final order in orders) order.id: order};

    final period = _period(today);
    final summary = MoneySummary.of(period, orders, payments);
    final received = [
      for (final payment in payments)
        if (period.contains(payment.paidAt)) payment,
    ];
    final shown = _showAllPayments
        ? received
        : received.take(_shownPayments).toList();

    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.xs,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                Transform.translate(
                  // The button's touch area is wider than its border.
                  offset: const Offset(-AppSpacing.xs, 0),
                  child: AppBoxedIconButton(
                    icon: Icons.chevron_left,
                    label: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'Revenue',
                  style: AppTypography.title.copyWith(
                    fontSize: 18,
                    letterSpacing: 18 * -0.02,
                    color: AppPalette.carbon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RangeTabs(
              selected: _range,
              onSelected: (range) => _choose(range, today),
            ),
            const SizedBox(height: 14),
            MoneyCard(
              label: 'Collected · ${periodLabel(period)}',
              amount: summary.collected,
              tiles: [
                MoneyTile(
                  label: 'Billed',
                  amount: summary.billed,
                  caption:
                      '${summary.orderCount} '
                      '${summary.orderCount == 1 ? 'order' : 'orders'}',
                ),
                MoneyTile(
                  label: 'Outstanding',
                  amount: summary.outstanding,
                  caption: 'on these orders',
                ),
              ],
            ),
            const SizedBox(height: 22),
            const AppSectionRule('Collected by month'),
            const SizedBox(height: 14),
            _MonthChart(
              totals: collectedByMonth(payments, last: period.last),
              period: period,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(child: AppSectionLabel('Payments received')),
                TextButton.icon(
                  onPressed: received.isEmpty
                      ? null
                      : () => _copy(received, byId, customers, settings),
                  icon: const Icon(Icons.copy_outlined, size: 15),
                  label: const Text('Copy CSV'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppPalette.oliveInk,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    textStyle: AppTypography.body.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            if (received.isEmpty)
              AppDashedBox(
                padding: const EdgeInsets.all(18),
                child: Text(
                  paymentsAsync.hasError
                      ? "Couldn't read the payments."
                      : 'No payments were received in this period.',
                  textAlign: TextAlign.center,
                  style: AppTypography.support.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              )
            else
              _PaymentList(
                payments: shown,
                orders: byId,
                customers: customers,
                settings: settings,
                today: today,
              ),
            if (received.length > shown.length) ...[
              const SizedBox(height: 10),
              AppButton(
                label: 'Show all ${received.length} payments',
                variant: AppButtonVariant.outlined,
                onPressed: () => setState(() => _showAllPayments = true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.selected, required this.onSelected});
  final _Range selected;
  final ValueChanged<_Range> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: AppPalette.surfaceControl,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color.fromRGBO(23, 25, 24, 0.07)),
    ),
    child: Row(
      children: [
        for (final range in _Range.values)
          Expanded(
            flex: range == _Range.custom ? 4 : 5,
            child: Semantics(
              selected: range == selected,
              inMutuallyExclusiveGroup: true,
              child: TextButton(
                onPressed: () => onSelected(range),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  fixedSize: const Size.fromHeight(40),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  backgroundColor: range == selected
                      ? AppPalette.carbon
                      : Colors.transparent,
                  foregroundColor: range == selected
                      ? AppPalette.white
                      : const Color.fromRGBO(23, 25, 24, 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: AppTypography.body.copyWith(
                    fontSize: 12.5,
                    fontWeight: range == selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                  animationDuration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.selection,
                ),
                child: Text(
                  range.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Labelled columns, one per month: the period being viewed in carbon and
/// the best other month in olive, so the comparison reads without colour.
class _MonthChart extends StatelessWidget {
  const _MonthChart({required this.totals, required this.period});
  final List<MonthTotal> totals;
  final Period period;

  static const _barArea = 110.0;

  @override
  Widget build(BuildContext context) {
    final most = totals.fold<double>(
      0,
      (max, t) => t.amount > max ? t.amount : max,
    );
    MonthTotal? best;
    for (final total in totals) {
      if (total.amount > 0 && (best == null || total.amount > best.amount)) {
        best = total;
      }
    }
    final bestShown = best != null && !period.overlapsMonth(best.month);
    final monthLabel = AppTypography.micro.copyWith(
      fontSize: 10,
      fontFeatures: AppTypography.tabularFigures,
      color: AppPalette.ink55,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _barArea + 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (index, total) in totals.indexed) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      label:
                          '${DateFormat('MMMM yyyy').format(total.month)}: '
                          '${formatRupees(total.amount)} collected',
                      child: ExcludeSemantics(
                        child: _Bar(
                          label: compactRupees(total.amount),
                          height: most == 0
                              ? 2
                              : (total.amount / most * _barArea).clamp(
                                  2,
                                  _barArea,
                                ),
                          current: period.overlapsMonth(total.month),
                          best: bestShown && total == best,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: AppPalette.lineStrong),
          const SizedBox(height: 7),
          Row(
            children: [
              for (final (index, total) in totals.indexed) ...[
                if (index > 0) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    DateFormat('MMM').format(total.month),
                    textAlign: TextAlign.center,
                    style: period.overlapsMonth(total.month)
                        ? monthLabel.copyWith(color: AppPalette.carbon)
                        : monthLabel,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 11),
          const Divider(height: 1, color: AppPalette.line),
          const SizedBox(height: 11),
          Wrap(
            spacing: 14,
            runSpacing: AppSpacing.xs,
            children: [
              const _Key(color: AppPalette.carbon, label: 'This period'),
              if (bestShown)
                _Key(
                  color: _Bar.bestColor,
                  label: 'Best month (${DateFormat('MMM').format(best.month)})',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.height,
    required this.current,
    required this.best,
  });

  final String label;
  final double height;
  final bool current;
  final bool best;

  static const bestColor = Color.fromRGBO(124, 128, 112, 0.45);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: AppTypography.micro.copyWith(
            fontSize: 10,
            fontWeight: current ? FontWeight.w700 : FontWeight.w600,
            fontFeatures: AppTypography.tabularFigures,
            color: current ? AppPalette.carbon : AppPalette.ink55,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Container(
        height: height,
        decoration: BoxDecoration(
          color: current
              ? AppPalette.carbon
              : best
              ? bestColor
              : const Color.fromRGBO(23, 25, 24, 0.14),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    ],
  );
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: AppTypography.support.copyWith(
          fontSize: 10.5,
          color: const Color.fromRGBO(23, 25, 24, 0.62),
        ),
      ),
    ],
  );
}

class _PaymentList extends StatelessWidget {
  const _PaymentList({
    required this.payments,
    required this.orders,
    required this.customers,
    required this.settings,
    required this.today,
  });

  final List<Payment> payments;
  final Map<String, Order> orders;
  final Map<String, Customer> customers;
  final ShopSettings settings;
  final DateTime today;

  String _day(DateTime time) {
    final days = DateTime.utc(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime.utc(time.year, time.month, time.day)).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return DateFormat(
      time.year == today.year ? 'd MMM' : 'd MMM yyyy',
    ).format(time);
  }

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
          for (final (index, payment) in payments.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: AppDashedLine(),
              ),
            _paymentRow(context, payment),
          ],
        ],
      ),
    );
  }

  Widget _paymentRow(BuildContext context, Payment payment) {
    final order = orders[payment.orderId];
    final number = order?.orderNumber;
    return InkWell(
      onTap: order == null ? null : () => context.push('/orders/${order.id}'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizing.minHitTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customers[order?.customerId]?.name ?? 'Unknown customer',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.carbon,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (number != null) settings.orderLabel(number),
                        payment.isAdvance
                            ? '${payment.method.label} advance'
                            : payment.method.label,
                        _day(payment.paidAt),
                      ].join(' · '),
                      style: AppTypography.support.copyWith(
                        fontSize: 11,
                        fontFeatures: AppTypography.tabularFigures,
                        color: const Color.fromRGBO(23, 25, 24, 0.58),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                formatRupees(payment.amount),
                style: AppTypography.numberMd.copyWith(
                  fontSize: 14.5,
                  color: AppPalette.carbon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

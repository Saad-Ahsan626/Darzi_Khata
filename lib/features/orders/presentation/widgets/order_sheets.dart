import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/formatting/rupee_input_formatter.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status_event.dart';
import 'package:tailor_khata/features/orders/domain/entities/payment.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/production_stepper.dart';

const _ink60 = Color.fromRGBO(23, 25, 24, 0.60);

final _sheetTitle = AppTypography.title.copyWith(
  fontSize: 18,
  letterSpacing: 18 * -0.02,
  color: AppPalette.carbon,
);

final _modalTitle = AppTypography.title.copyWith(
  fontSize: 19,
  letterSpacing: 19 * -0.02,
  color: AppPalette.carbon,
);

final _modalBody = AppTypography.support.copyWith(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.55,
);

final _fieldLabel = AppTypography.sectionLabel.copyWith(
  fontSize: 10.5,
  letterSpacing: 10.5 * 0.09,
  color: AppPalette.ink55,
);

final _tabular = AppTypography.support.copyWith(
  fontSize: 11.5,
  fontFeatures: AppTypography.tabularFigures,
  color: AppPalette.ink55,
);

final _sheetMotion = AnimationStyle(
  duration: AppMotion.sheet,
  curve: AppMotion.curve,
);

String _dayMonth(DateTime time) => DateFormat('d MMM').format(time);

/// The order's money as label and amount rows, with the amount still owed
/// on a carbon row at the foot.
class OrderMoneyTable extends StatelessWidget {
  const OrderMoneyTable({
    super.key,
    required this.rows,
    required this.footLabel,
    required this.footAmount,
    this.compact = false,
  });

  final List<(String, num)> rows;
  final String footLabel;
  final num footAmount;

  /// Tighter rows, for dialogs.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 13, vertical: 11)
        : const EdgeInsets.symmetric(horizontal: 14, vertical: 12);
    final label = AppTypography.support.copyWith(fontSize: 12.5, color: _ink60);
    final value = AppTypography.body.copyWith(
      fontSize: compact ? 13.5 : 14,
      fontWeight: FontWeight.w600,
      fontFeatures: AppTypography.tabularFigures,
      color: AppPalette.carbon,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, (name, amount)) in rows.indexed) ...[
            if (index > 0)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding.left),
                child: const AppDashedLine(),
              ),
            Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(child: Text(name, style: label)),
                  Text(formatRupees(amount), style: value),
                ],
              ),
            ),
          ],
          ColoredBox(
            color: AppPalette.carbon,
            child: Padding(
              padding: padding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      footLabel,
                      style: label.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppPalette.onCarbonMuted,
                      ),
                    ),
                  ),
                  Text(
                    formatRupees(footAmount),
                    style: value.copyWith(
                      fontSize: compact ? 15 : 16,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A grey note with an info icon, used under choices in sheets.
class _InfoNote extends StatelessWidget {
  const _InfoNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: AppPalette.surfaceSunken,
      borderRadius: BorderRadius.circular(AppRadii.control),
      border: Border.all(color: AppPalette.line),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 17, color: AppPalette.ink70),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: AppTypography.support.copyWith(
              fontSize: 12,
              height: 1.45,
              fontFeatures: AppTypography.tabularFigures,
            ),
          ),
        ),
      ],
    ),
  );
}

// Change production status

/// Lets the shop move an order to another production stage. Resolves to the
/// chosen stage, or null when nothing should change.
Future<String?> showChangeStatusSheet(
  BuildContext context, {
  required Order order,
  required List<OrderStatusEvent> history,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  sheetAnimationStyle: _sheetMotion,
  builder: (context) => _ChangeStatusSheet(order: order, history: history),
);

class _ChangeStatusSheet extends StatefulWidget {
  const _ChangeStatusSheet({required this.order, required this.history});
  final Order order;
  final List<OrderStatusEvent> history;

  @override
  State<_ChangeStatusSheet> createState() => _ChangeStatusSheetState();
}

class _ChangeStatusSheetState extends State<_ChangeStatusSheet> {
  static const _stages = [...OrderStatus.production, OrderStatus.delivered];

  late final int _current = OrderStatus.production
      .indexOf(widget.order.status)
      .clamp(0, OrderStatus.production.length - 1);

  /// The next stage is offered first; Ready has none to move on to here.
  late String _selected = OrderStatus
      .production[(_current + 1).clamp(0, OrderStatus.production.length - 1)];

  /// When the order last entered [stage].
  DateTime? _enteredAt(String stage) {
    for (final event in widget.history.reversed) {
      if (event.status == stage) return event.changedAt;
    }
    return null;
  }

  /// When work on [stage] finished: the first later stage after it began.
  DateTime? _completedAt(int stage) {
    final began = _enteredAt(_stages[stage]);
    if (began == null) return null;
    for (final event in widget.history) {
      if (!event.changedAt.isBefore(began) &&
          _stages.indexOf(event.status) > stage) {
        return event.changedAt;
      }
    }
    return null;
  }

  String _subtitle(int index) {
    if (_stages[index] == OrderStatus.delivered) {
      return 'Use “Mark Delivered” instead';
    }
    if (index < _current) {
      final completed = _completedAt(index);
      return completed == null ? 'Done' : 'Completed ${_dayMonth(completed)}';
    }
    if (index == _current) {
      final since = _enteredAt(_stages[index]);
      return since == null
          ? 'Current stage'
          : 'Current stage · since ${_dayMonth(since)}';
    }
    return 'Not started';
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.order.balance;
    final changed = _selected != OrderStatus.production[_current];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Change production status', style: _sheetTitle),
            const SizedBox(height: 6),
            Text(
              'This records work progress only. It does not affect payment.',
              style: AppTypography.support.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            for (final (index, stage) in _stages.indexed) ...[
              if (index > 0) const SizedBox(height: AppSpacing.sm),
              _StageOption(
                label: stage,
                subtitle: _subtitle(index),
                done: index < _current,
                current: index == _current,
                selected: stage == _selected,
                onTap: stage == OrderStatus.delivered
                    ? null
                    : () => setState(() => _selected = stage),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _InfoNote(
              balance > 0
                  ? '${formatRupees(balance)} remains outstanding on this '
                        'order either way.'
                  : 'Nothing is owed on this order.',
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: AppButton(
                    label: 'Save Status',
                    onPressed: changed
                        ? () => Navigator.pop(context, _selected)
                        : null,
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

class _StageOption extends StatelessWidget {
  const _StageOption({
    required this.label,
    required this.subtitle,
    required this.done,
    required this.current,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool done;
  final bool current;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: selected
          ? const BorderSide(color: AppPalette.carbon, width: 2)
          : BorderSide(color: done ? AppPalette.line : AppPalette.lineStrong),
    );
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected
            ? AppPalette.oliveFill10
            : done
            ? AppPalette.surfaceSunken
            : AppPalette.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                StageDot(done: done, current: current),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTypography.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: onTap == null ? _ink60 : AppPalette.carbon,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(subtitle, style: _tabular),
                    ],
                  ),
                ),
                if (current)
                  const AppStatusBadge(label: 'Now', tone: AppBadgeTone.olive),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Record payment

/// What the shop entered in the payment sheet.
typedef PaymentEntry = ({double amount, PaymentMethod method});

/// Records money received against an order's outstanding balance. Resolves
/// to the amount and method, or null when cancelled.
Future<PaymentEntry?> showRecordPaymentSheet(
  BuildContext context, {
  required Order order,
  required String subtitle,
}) => showModalBottomSheet<PaymentEntry>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  sheetAnimationStyle: _sheetMotion,
  builder: (context) => _RecordPaymentSheet(order: order, subtitle: subtitle),
);

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cash => 'Cash',
    PaymentMethod.bank => 'Bank',
    PaymentMethod.easypaisa => 'Easypaisa',
  };
}

class _RecordPaymentSheet extends StatefulWidget {
  const _RecordPaymentSheet({required this.order, required this.subtitle});
  final Order order;
  final String subtitle;

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  late final double _balance = widget.order.balance;
  late double _amount = _balance;
  late final _controller = TextEditingController(
    text: rupeesInputText(_balance),
  );
  PaymentMethod _method = PaymentMethod.cash;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _choose(double amount) {
    setState(() => _amount = amount);
    _controller.value = TextEditingValue(
      text: rupeesInputText(amount),
      selection: TextSelection.collapsed(
        offset: rupeesInputText(amount).length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final half = (_balance / 2).roundToDouble();
    final quick = <(String, double)>[
      ('Full ${formatRupees(_balance)}', _balance),
      if (half > 0 && half < _balance) ('Half', half),
      if (_balance > 1000) ('Rs 1,000', 1000),
    ];
    final tooMuch = _amount > _balance;
    final after = (_balance - _amount).clamp(0, _balance);
    final valid = _amount > 0 && !tooMuch;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
          ),
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
                        Text('Record payment', style: _sheetTitle),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          style: _tabular.copyWith(fontSize: 12, color: _ink60),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 19),
                    style: IconButton.styleFrom(
                      backgroundColor: AppPalette.surfaceControl,
                      foregroundColor: _ink60,
                      fixedSize: const Size.square(40),
                      minimumSize: const Size.square(40),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OrderMoneyTable(
                rows: [
                  ('Order total', widget.order.totalAmount),
                  ('Already paid', widget.order.paidAmount),
                ],
                footLabel: 'Outstanding',
                footAmount: _balance,
              ),
              const SizedBox(height: 18),
              Text('AMOUNT RECEIVED NOW', style: _fieldLabel),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 66,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPalette.carbon, width: 2),
                ),
                child: Row(
                  children: [
                    Text(
                      'Rs',
                      style: AppTypography.body.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppPalette.ink45,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: const [RupeeInputFormatter()],
                        cursorColor: AppPalette.carbon,
                        cursorWidth: 2,
                        onChanged: (text) => setState(
                          () => _amount = (parseRupees(text) ?? 0).toDouble(),
                        ),
                        style: AppTypography.numberLg.copyWith(
                          fontSize: 30,
                          letterSpacing: 30 * -0.03,
                          color: AppPalette.carbon,
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: '0',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (tooMuch) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppPalette.carbon,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'More than the ${formatRupees(_balance)} outstanding',
                        style: AppTypography.support.copyWith(
                          color: AppPalette.carbon,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (index, (label, amount)) in quick.indexed) ...[
                    if (index > 0) const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _QuickAmount(
                        label: label,
                        selected: _amount == amount,
                        onTap: () => _choose(amount),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('METHOD', style: _fieldLabel),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  for (final method in PaymentMethod.values) ...[
                    if (method != PaymentMethod.values.first)
                      const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _MethodOption(
                        label: method.label,
                        selected: method == _method,
                        onTap: () => setState(() => _method = method),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppPalette.carbon, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BALANCE AFTER THIS PAYMENT',
                            style: _fieldLabel.copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            formatRupees(after),
                            style: AppTypography.numberMd.copyWith(
                              fontSize: 22,
                              letterSpacing: 22 * -0.025,
                              color: AppPalette.carbon,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (valid && after == 0)
                      const AppStatusBadge(label: 'Paid in full'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: valid
                    ? 'Record ${formatRupees(_amount)}'
                    : 'Record payment',
                onPressed: valid
                    ? () => Navigator.pop(context, (
                        amount: _amount,
                        method: _method,
                      ))
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                'Saved on this device',
                textAlign: TextAlign.center,
                style: AppTypography.support.copyWith(
                  fontSize: 11.5,
                  color: AppPalette.ink45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmount extends StatelessWidget {
  const _QuickAmount({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, AppSizing.minHitTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        backgroundColor: selected ? AppPalette.oliveFill14 : AppPalette.white,
        foregroundColor: selected ? AppPalette.oliveInk : AppPalette.carbon,
        side: BorderSide(
          color: selected ? AppPalette.oliveBorder : AppPalette.lineStrong,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: AppTypography.body.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          fontFeatures: AppTypography.tabularFigures,
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    inMutuallyExclusiveGroup: true,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        backgroundColor: selected ? AppPalette.carbon : AppPalette.white,
        foregroundColor: selected ? AppPalette.white : AppPalette.carbon,
        side: BorderSide(
          color: selected ? AppPalette.carbon : AppPalette.lineStrong,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: AppTypography.body.copyWith(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}

// Delivery

/// How the shop chose to go on from the delivery confirmation.
enum DeliveryChoice { deliver, recordPaymentFirst }

/// Confirms delivery. With a balance still owed it states the amount and
/// offers to record a payment first, rather than blocking delivery.
Future<DeliveryChoice?> showDeliverDialog(
  BuildContext context, {
  required Order order,
  required String customerName,
}) {
  final balance = order.balance;
  return showDialog<DeliveryChoice>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.screenPadding),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AppIconTile(
                icon: balance > 0
                    ? Icons.warning_amber_rounded
                    : Icons.inventory_2_outlined,
                size: 50,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              balance > 0
                  ? 'Deliver with ${formatRupees(balance)} unpaid?'
                  : 'Mark as delivered?',
              style: _modalTitle,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              balance > 0
                  ? 'The order will be marked delivered and the balance will '
                        "stay on $customerName's account."
                  : '$customerName has paid in full. Once delivered, the '
                        'order can no longer change stage.',
              style: _modalBody,
            ),
            if (balance > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              OrderMoneyTable(
                compact: true,
                rows: [
                  ('Total', order.totalAmount),
                  ('Paid', order.paidAmount),
                ],
                footLabel: 'Stays outstanding',
                footAmount: balance,
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: balance > 0 ? 'Deliver, keep balance' : 'Mark Delivered',
              onPressed: () => Navigator.pop(context, DeliveryChoice.deliver),
            ),
            if (balance > 0) ...[
              const SizedBox(height: 10),
              AppButton(
                label: 'Record payment first',
                variant: AppButtonVariant.olive,
                onPressed: () =>
                    Navigator.pop(context, DeliveryChoice.recordPaymentFirst),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.text,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}

// Delete

/// Asks before deleting an order with its payments and history. Resolves to
/// true only when the deletion is confirmed.
Future<bool> showDeleteOrderDialog(
  BuildContext context, {
  required Order order,
  required String orderLabel,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.screenPadding),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIconTile(icon: Icons.delete_outline, size: 50),
            const SizedBox(height: AppSpacing.lg),
            Text('Delete $orderLabel?', style: _modalTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This removes the ${order.garmentType} order, its payments and '
              'its status history from this device. It cannot be undone.',
              style: _modalBody,
            ),
            if (order.balance > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppPalette.carbon, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: AppPalette.carbon,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${formatRupees(order.balance)} outstanding will be '
                        'lost from your records',
                        style: AppTypography.support.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          fontFeatures: AppTypography.tabularFigures,
                          color: AppPalette.carbon,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            AppButton(
              label: 'Keep order',
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Delete permanently',
              icon: Icons.delete_outline,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}

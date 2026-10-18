import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/formatting/rupee_input_formatter.dart';
import 'package:tailor_khata/core/providers/clock_provider.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer_activity.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customer_activity_provider.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_avatar.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_dialogs.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/garment_template.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/measurement_format.dart';
import 'package:tailor_khata/features/measurements/presentation/providers/measurements_notifier.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/customer_picker_sheet.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';

const _ink60 = Color.fromRGBO(23, 25, 24, 0.60);

final _fieldLabel = AppTypography.sectionLabel.copyWith(
  fontSize: 10.5,
  letterSpacing: 10.5 * 0.09,
  color: AppPalette.ink55,
);

/// A new order, or changes to one with [orderId]. The balance is worked out
/// from the total and advance and stays in view while typing.
class NewEditOrderScreen extends ConsumerStatefulWidget {
  const NewEditOrderScreen({super.key, this.initialCustomerId, this.orderId});

  /// Customer to preselect when the order is started from a customer's page.
  final String? initialCustomerId;

  /// The order being edited; null for a new order.
  final String? orderId;

  @override
  ConsumerState<NewEditOrderScreen> createState() => _NewEditOrderScreenState();
}

class _NewEditOrderScreenState extends ConsumerState<NewEditOrderScreen> {
  static const _defaultGarment = 'Shalwar Kameez';

  final _fabric = TextEditingController();
  final _note = TextEditingController();
  final _total = TextEditingController();
  final _advance = TextEditingController();
  final _totalFocus = FocusNode();
  final _advanceFocus = FocusNode();

  String? _customerId;

  /// Chosen garment; until then, the customer's most recent profile's.
  String? _garment;
  int _pieces = 1;

  /// The profile linked by hand. Until one is, the customer's formal fit
  /// for the garment is used, or their casual fit.
  String? _measurementId;
  bool _measurementChosen = false;
  late DateTime _deliveryDate;
  bool _showNote = false;

  /// The order being edited, once read.
  Order? _editing;
  bool _loaded = false;

  /// Something was entered or changed since the form opened.
  bool _dirty = false;
  bool _saving = false;

  /// Save was pressed, so missing details are pointed out.
  bool _submitted = false;
  String? _totalProblem;

  bool get _isEditing => widget.orderId != null;

  @override
  void initState() {
    super.initState();
    _customerId = widget.initialCustomerId;
    final today = ref.read(clockProvider)();
    _deliveryDate = DateTime(today.year, today.month, today.day + 7);
    for (final controller in [_fabric, _note, _total, _advance]) {
      controller.addListener(_changed);
    }
    _totalFocus.addListener(() => setState(() {}));
    _advanceFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final controller in [_fabric, _note, _total, _advance]) {
      controller.dispose();
    }
    _totalFocus.dispose();
    _advanceFocus.dispose();
    super.dispose();
  }

  void _changed() {
    if (!_loaded) return;
    setState(() {
      _dirty = true;
      _totalProblem = null;
    });
  }

  void _edit(VoidCallback change) => setState(() {
    change();
    _dirty = true;
  });

  /// Fills the form from the order being edited, once it is available.
  void _load(Order order) {
    _editing = order;
    _customerId = order.customerId;
    _garment = order.garmentType;
    _pieces = order.pieces;
    _measurementId = order.measurementId;
    _measurementChosen = true;
    _deliveryDate = order.deliveryDate;
    _fabric.text = order.fabric ?? '';
    _note.text = order.notes ?? '';
    _showNote = _note.text.trim().isNotEmpty;
    _total.text = rupeesInputText(order.totalAmount);
  }

  double get _totalAmount => (parseRupees(_total.text) ?? 0).toDouble();

  double get _advanceAmount => _editing != null
      ? _editing!.paidAmount
      : (parseRupees(_advance.text) ?? 0).toDouble();

  String? get _advanceProblem =>
      _editing == null && _advanceAmount > _totalAmount && _totalAmount > 0
      ? "The advance can't be more than the total"
      : null;

  /// The customer's profiles for [garment], by fit.
  Map<String, Measurement> _profiles(String? customerId, String garment) => {
    for (final profile
        in ref.watch(measurementsNotifierProvider).valueOrNull ??
            const <Measurement>[])
      if (profile.customerId == customerId && profile.garmentType == garment)
        profile.fitProfile: profile,
  };

  String _garmentFor(String? customerId) {
    if (_garment != null) return _garment!;
    Measurement? latest;
    for (final profile
        in ref.watch(measurementsNotifierProvider).valueOrNull ??
            const <Measurement>[]) {
      if (profile.customerId != customerId) continue;
      if (latest == null || profile.updatedAt.isAfter(latest.updatedAt)) {
        latest = profile;
      }
    }
    return latest?.garmentType ?? _defaultGarment;
  }

  String? _linkedProfile(Map<String, Measurement> profiles) {
    if (_measurementChosen) {
      return profiles.values.any((p) => p.id == _measurementId)
          ? _measurementId
          : null;
    }
    return (profiles[FitProfile.formal] ?? profiles[FitProfile.casual])?.id;
  }

  Future<void> _chooseCustomer(List<Customer> customers) async {
    final pick = await showCustomerPicker(context, customers: customers);
    if (pick == null || !mounted) return;
    if (pick.customer case final customer?) {
      return _edit(() => _selectCustomer(customer.id));
    }
    final added = await context.push<String>(
      Uri(
        path: '/customers/new',
        queryParameters: {
          if (pick.newName?.isNotEmpty ?? false) 'name': pick.newName!,
        },
      ).toString(),
    );
    if (added != null && mounted) _edit(() => _selectCustomer(added));
  }

  void _selectCustomer(String id) {
    if (id == _customerId) return;
    _customerId = id;
    if (!_isEditing) _garment = null;
    _measurementChosen = false;
  }

  Future<void> _chooseOtherGarment() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Other garment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Achkan'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Use'),
          ),
        ],
      ),
    );
    controller.dispose();
    final garment = name?.trim() ?? '';
    if (garment.isEmpty || !mounted) return;
    _edit(() {
      _garment = garment;
      _measurementChosen = false;
    });
  }

  Future<void> _chooseDeliveryDate() async {
    final now = ref.read(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final first = _deliveryDate.isBefore(today) ? _deliveryDate : today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: first,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      helpText: 'Delivery date',
    );
    if (picked != null && mounted) _edit(() => _deliveryDate = picked);
  }

  void _openMeasurements(String customerId, String garment, String? fit) {
    context.push(
      Uri(
        path: '/customers/$customerId/measurements',
        queryParameters: {'garment': garment, 'fit': ?fit},
      ).toString(),
    );
  }

  Future<void> _save({
    required Customer? customer,
    required String garment,
    required String? measurementId,
  }) async {
    FocusScope.of(context).unfocus();
    setState(() => _submitted = true);
    final editing = _editing;
    if (customer == null ||
        _totalAmount <= 0 ||
        _advanceProblem != null ||
        (editing != null && _totalAmount < editing.paidAmount)) {
      return;
    }

    final fabric = _fabric.text.trim();
    final note = _note.text.trim();
    final order = Order(
      id: editing?.id ?? const Uuid().v4(),
      customerId: customer.id,
      measurementId: measurementId,
      orderNumber: editing?.orderNumber,
      garmentType: garment,
      pieces: _pieces,
      fabric: fabric.isEmpty ? null : fabric,
      notes: note.isEmpty ? null : note,
      status: editing?.status ?? OrderStatus.received,
      deliveryDate: _deliveryDate,
      totalAmount: _totalAmount,
      paidAmount: _advanceAmount,
      createdAt: editing?.createdAt ?? ref.read(clockProvider)(),
      deliveredAt: editing?.deliveredAt,
      ownerId: editing?.ownerId ?? 'guest',
      syncStatus: editing?.syncStatus ?? 0,
    );

    setState(() => _saving = true);
    final orders = ref.read(ordersNotifierProvider.notifier);
    final failure = editing == null
        ? await orders.addOrder(order)
        : await orders.updateOrder(order);
    if (!mounted) return;
    setState(() => _saving = false);

    if (failure == null) {
      _dirty = false;
      if (editing != null) {
        showAppToast(context, message: 'Order updated');
        context.pop();
        return;
      }
      final saved = ref
          .read(ordersNotifierProvider)
          .valueOrNull
          ?.where((o) => o.id == order.id)
          .firstOrNull;
      final settings = ref.read(shopSettingsProvider).valueOrNull;
      final number = saved?.orderNumber;
      showAppToast(
        context,
        message: number == null || settings == null
            ? 'Order saved'
            : 'Order ${settings.orderLabel(number)} saved',
        detail: order.balance > 0
            ? '${formatRupees(order.balance)} due on delivery'
            : 'Paid in full',
      );
      context.pushReplacement('/orders/${order.id}');
      return;
    }
    if (failure is ValidationFailure) {
      setState(() => _totalProblem = failure.message);
      return;
    }
    final retry = await showSaveFailureSheet(
      context,
      failure: failure,
      at: ref.read(clockProvider)(),
      title: "Couldn't save order",
    );
    if (retry && mounted) {
      await _save(
        customer: customer,
        garment: garment,
        measurementId: measurementId,
      );
    }
  }

  Future<void> _leave() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isEditing ? 'Discard your changes?' : 'Discard this order?',
        ),
        content: Text(
          _isEditing
              ? 'The order stays as it was saved.'
              : 'What you entered for this order will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    _dirty = false;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing && !_loaded) {
      final orders = ref.watch(ordersNotifierProvider).valueOrNull;
      final order = orders?.where((o) => o.id == widget.orderId).firstOrNull;
      if (order == null) {
        return Scaffold(
          backgroundColor: AppPalette.white,
          appBar: AppBar(),
          body: Center(
            child: orders == null
                ? const AppLoading()
                : const AppFeedback(
                    title: 'Order not found',
                    message: 'This order is no longer saved on this device.',
                    icon: Icons.receipt_long_outlined,
                  ),
          ),
        );
      }
      _load(order);
    }
    _loaded = true;

    final customers =
        ref.watch(customersNotifierProvider).valueOrNull ?? const <Customer>[];
    final customer = customers.where((c) => c.id == _customerId).firstOrNull;
    final garment = _garmentFor(customer?.id);
    final profiles = _profiles(customer?.id, garment);
    final measurementId = _linkedProfile(profiles);
    final settings = ref.watch(shopSettingsProvider).valueOrNull;
    final number = _editing?.orderNumber ?? settings?.nextOrderNumber;
    final balance = (_totalAmount - _advanceAmount).clamp(0, double.infinity);

    final totalProblem =
        _totalProblem ??
        (!_submitted
            ? null
            : _totalAmount <= 0
            ? 'Enter the total price'
            : _editing != null && _totalAmount < _editing!.paidAmount
            ? "The total can't be less than the "
                  '${formatRupees(_editing!.paidAmount)} already paid'
            : null);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _leave();
      },
      child: Scaffold(
        backgroundColor: AppPalette.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: Row(
                  children: [
                    AppBoxedIconButton(
                      icon: Icons.chevron_left,
                      label: 'Back',
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Order' : 'New Order',
                        style: AppTypography.title.copyWith(
                          fontSize: 18,
                          letterSpacing: 18 * -0.02,
                          color: AppPalette.carbon,
                        ),
                      ),
                    ),
                    if (number != null && settings != null)
                      Text(
                        settings.orderLabel(number),
                        style: AppTypography.micro.copyWith(
                          letterSpacing: 11 * 0.07,
                          fontFeatures: AppTypography.tabularFigures,
                          color: AppPalette.ink45,
                        ),
                      ),
                  ],
                ),
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
                    Text('CUSTOMER', style: _fieldLabel),
                    const SizedBox(height: AppSpacing.sm),
                    _CustomerCard(
                      customer: customer,
                      activity: customer == null
                          ? null
                          : ref.watch(customerActivityProvider)[customer.id],
                      problem: _submitted && customer == null
                          ? 'Choose who the order is for'
                          : null,
                      onChange: _saving
                          ? null
                          : () => _chooseCustomer(customers),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _HeaderRow(
                      children: [
                        Expanded(child: Text('GARMENT', style: _fieldLabel)),
                        _PiecesStepper(
                          pieces: _pieces,
                          onChanged: (pieces) => _edit(() => _pieces = pieces),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _GarmentChoice(
                      selected: garment,
                      onSelected: (name) => _edit(() {
                        _garment = name;
                        _measurementChosen = false;
                      }),
                      onOther: _chooseOtherGarment,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _HeaderRow(
                      children: [
                        Expanded(
                          child: Text(
                            'MEASUREMENT PROFILE',
                            style: _fieldLabel,
                          ),
                        ),
                        if (customer != null)
                          TextButton(
                            onPressed: () => _openMeasurements(
                              customer.id,
                              garment,
                              profiles.values
                                  .where((p) => p.id == measurementId)
                                  .firstOrNull
                                  ?.fitProfile,
                            ),
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
                            child: const Text('View'),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (customer == null)
                      AppDashedBox(
                        radius: 13,
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Choose a customer to link their measurements.',
                          style: AppTypography.support.copyWith(fontSize: 12.5),
                        ),
                      )
                    else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final fit in [
                            FitProfile.formal,
                            FitProfile.casual,
                          ]) ...[
                            if (fit != FitProfile.formal)
                              const SizedBox(width: 10),
                            Expanded(
                              child: _ProfileOption(
                                fit: fit,
                                profile: profiles[fit],
                                selected:
                                    profiles[fit] != null &&
                                    profiles[fit]!.id == measurementId,
                                onTap: () {
                                  final profile = profiles[fit];
                                  if (profile == null) {
                                    return _openMeasurements(
                                      customer.id,
                                      garment,
                                      fit,
                                    );
                                  }
                                  _edit(() {
                                    _measurementChosen = true;
                                    _measurementId = profile.id == measurementId
                                        ? null
                                        : profile.id;
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('FABRIC', style: _fieldLabel),
                              const SizedBox(height: AppSpacing.sm),
                              Semantics(
                                label: 'Fabric',
                                child: TextField(
                                  controller: _fabric,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 13.5,
                                    color: AppPalette.carbon,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'e.g. Cotton, sky blue',
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('DELIVERY', style: _fieldLabel),
                              const SizedBox(height: AppSpacing.sm),
                              _DateButton(
                                date: _deliveryDate,
                                onTap: _chooseDeliveryDate,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_showNote)
                      _NoteField(
                        controller: _note,
                        autofocus: _note.text.isEmpty,
                        onRemove: () => _edit(() {
                          _note.clear();
                          _showNote = false;
                        }),
                      )
                    else
                      _AddNoteButton(
                        onTap: () => setState(() => _showNote = true),
                      ),
                    const SizedBox(height: 14),
                    _PaymentCard(
                      total: _total,
                      advance: _advance,
                      totalFocus: _totalFocus,
                      advanceFocus: _advanceFocus,
                      paidSoFar: _editing?.paidAmount,
                      balance: balance.toDouble(),
                      totalProblem: totalProblem,
                      advanceProblem: _advanceProblem,
                    ),
                  ],
                ),
              ),
              _SaveBar(
                balance: balance.toDouble(),
                label: _isEditing ? 'Save Changes' : 'Save Order',
                saving: _saving,
                onSave: () => _save(
                  customer: customer,
                  garment: garment,
                  measurementId: measurementId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A section label with room for a control beside it, so sections line
/// up whether the control is there or not.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizing.minHitTarget,
    child: Row(children: children),
  );
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.activity,
    required this.problem,
    required this.onChange,
  });

  final Customer? customer;
  final CustomerActivity? activity;
  final String? problem;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final customer = this.customer;
    if (customer == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.person_search_outlined, size: 20),
            label: const Text('Choose customer'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(62),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              side: BorderSide(
                color: problem == null
                    ? AppPalette.lineStrong
                    : AppPalette.carbon,
                width: problem == null ? 1 : 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (problem != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Problem(problem!),
          ],
        ],
      );
    }
    final phone = formatPhone(customer.phone);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.carbon, width: 1.5),
      ),
      child: Row(
        children: [
          CustomerAvatar(
            customer: customer,
            size: 40,
            tone: (activity?.isActive ?? false)
                ? CustomerAvatarTone.active
                : CustomerAvatarTone.quiet,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.carbon,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  phone.isEmpty ? 'No phone number' : phone,
                  style: AppTypography.support.copyWith(
                    fontSize: 11.5,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              backgroundColor: AppPalette.surfaceControl,
              foregroundColor: AppPalette.carbon,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: AppTypography.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem(this.message, {this.onCarbon = false});
  final String message;
  final bool onCarbon;

  @override
  Widget build(BuildContext context) {
    final ink = onCarbon ? AppPalette.white : AppPalette.carbon;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 16, color: ink),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: AppTypography.support.copyWith(
                fontSize: 12,
                fontFeatures: AppTypography.tabularFigures,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PiecesStepper extends StatelessWidget {
  const _PiecesStepper({required this.pieces, required this.onChanged});
  final int pieces;
  final ValueChanged<int> onChanged;

  static const _max = 99;

  @override
  Widget build(BuildContext context) {
    final style = IconButton.styleFrom(
      foregroundColor: AppPalette.carbon,
      fixedSize: const Size.square(32),
      minimumSize: const Size.square(32),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.padded,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppPalette.lineStrong),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'One piece fewer',
          onPressed: pieces > 1 ? () => onChanged(pieces - 1) : null,
          icon: const Icon(Icons.remove, size: 16),
          style: style,
        ),
        Semantics(
          liveRegion: true,
          child: SizedBox(
            width: 50,
            child: Text(
              '$pieces ${pieces == 1 ? 'pc' : 'pcs'}',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: AppTypography.tabularFigures,
                color: AppPalette.carbon,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'One piece more',
          onPressed: pieces < _max ? () => onChanged(pieces + 1) : null,
          icon: const Icon(Icons.add, size: 16),
          style: style,
        ),
      ],
    );
  }
}

class _GarmentChoice extends StatelessWidget {
  const _GarmentChoice({
    required this.selected,
    required this.onSelected,
    required this.onOther,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onOther;

  @override
  Widget build(BuildContext context) {
    final names = [for (final garment in GarmentTemplates.all) garment.name];
    if (!names.contains(selected)) names.add(selected);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final name in names) ...[
            _GarmentChip(
              label: name,
              selected: name == selected,
              onTap: () => onSelected(name),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          _GarmentChip(label: '+ Other', dashed: true, onTap: onOther),
        ],
      ),
    );
  }
}

class _GarmentChip extends StatelessWidget {
  const _GarmentChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.dashed = false,
  });

  final String label;
  final bool selected;
  final bool dashed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(label);
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 42),
          fixedSize: const Size.fromHeight(42),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: dashed
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: selected ? AppPalette.carbon : Colors.transparent,
          foregroundColor: selected
              ? AppPalette.white
              : dashed
              ? _ink60
              : AppPalette.carbon,
          side: dashed
              ? BorderSide.none
              : BorderSide(
                  color: selected ? AppPalette.carbon : AppPalette.lineStrong,
                ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: AppTypography.body.copyWith(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
          animationDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : AppMotion.selection,
        ),
        // The dashed outline is drawn inside, so it matches the visible chip
        // rather than its larger touch area.
        child: dashed
            ? AppDashedBox(
                radius: AppRadii.control,
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: text,
                ),
              )
            : text,
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.fit,
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final String fit;
  final Measurement? profile;
  final bool selected;
  final VoidCallback onTap;

  /// `Kameez length` as `Length`, to fit two values on a narrow card.
  static String _shortLabel(String label) {
    final word = label.split(' ').last;
    return word[0].toUpperCase() + word.substring(1);
  }

  /// The first two recorded values, such as `Chest 40.5 · Length 42.0`.
  String get _summary {
    final profile = this.profile!;
    final data = profile.measurementData;
    final template = GarmentTemplates.named(
      profile.garmentType,
    ).including(data.keys);
    final values = [
      for (final field in template.fields)
        if (data[field.key] case final value?)
          '${_shortLabel(field.label)} ${formatMeasurement(value, profile.unit)}',
    ];
    return values.isEmpty ? 'No values yet' : values.take(2).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final title = AppTypography.body.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: selected ? AppPalette.carbon : AppPalette.ink70,
    );
    final detail = AppTypography.support.copyWith(
      fontSize: 11,
      fontFeatures: AppTypography.tabularFigures,
      color: selected ? _ink60 : AppPalette.ink55,
    );
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 15, color: AppPalette.carbon),
                const SizedBox(width: 6),
              ] else if (profile == null) ...[
                const Icon(Icons.add, size: 15, color: AppPalette.ink55),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  profile == null ? 'Take $fit' : fit,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: title,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            profile == null ? 'Not measured yet' : _summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: detail,
          ),
        ],
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: selected
          ? const BorderSide(color: AppPalette.carbon, width: 1.5)
          : profile == null
          ? BorderSide.none
          : const BorderSide(color: AppPalette.line),
    );
    final option = Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppPalette.oliveFill10 : AppPalette.white,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, customBorder: shape, child: content),
      ),
    );
    return profile == null ? AppDashedBox(radius: 13, child: option) : option;
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Delivery date',
    button: true,
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today_outlined, size: 17),
      label: Text(
        DateFormat('d MMM yyyy').format(date),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        foregroundColor: AppPalette.carbon,
        iconColor: AppPalette.ink70,
        side: const BorderSide(color: AppPalette.lineStrong),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: AppTypography.body.copyWith(
          fontSize: 13.5,
          fontFeatures: AppTypography.tabularFigures,
        ),
      ),
    ),
  );
}

class _AddNoteButton extends StatelessWidget {
  const _AddNoteButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppDashedBox(
    radius: AppRadii.control,
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.control),
        child: SizedBox(
          height: AppSizing.minHitTarget,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: AppPalette.ink45),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Add a note for the cutter (optional)',
                    style: AppTypography.body.copyWith(
                      fontSize: 13.5,
                      color: AppPalette.ink45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.autofocus,
    required this.onRemove,
  });

  final TextEditingController controller;
  final bool autofocus;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text('NOTE FOR THE CUTTER', style: _fieldLabel)),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: AppPalette.ink70,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              textStyle: AppTypography.body.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
      Semantics(
        label: 'Note for the cutter',
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          style: AppTypography.body.copyWith(
            fontSize: 13.5,
            color: AppPalette.carbon,
          ),
          decoration: const InputDecoration(
            hintText: 'e.g. Collar 1 inch wider, no pocket',
            isDense: true,
            contentPadding: EdgeInsets.all(13),
          ),
        ),
      ),
    ],
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.total,
    required this.advance,
    required this.totalFocus,
    required this.advanceFocus,
    required this.paidSoFar,
    required this.balance,
    required this.totalProblem,
    required this.advanceProblem,
  });

  final TextEditingController total;
  final TextEditingController advance;
  final FocusNode totalFocus;
  final FocusNode advanceFocus;

  /// Payments already on the order being edited. They are recorded from
  /// the order page, not here.
  final double? paidSoFar;
  final double balance;
  final String? totalProblem;
  final String? advanceProblem;

  static const _muted = Color.fromRGBO(255, 255, 255, 0.55);

  @override
  Widget build(BuildContext context) {
    final fieldLabel = AppTypography.support.copyWith(
      fontSize: 10.5,
      color: _muted,
    );
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppPalette.carbon,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 10,
            child: AppTickPattern(color: Color(0x33FFFFFF), spacing: 9),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PAYMENT',
                  style: AppTypography.sectionLabel.copyWith(
                    fontSize: 10,
                    letterSpacing: 10 * 0.11,
                    color: const Color.fromRGBO(255, 255, 255, 0.58),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Total price', style: fieldLabel),
                          const SizedBox(height: 6),
                          _MoneyField(
                            label: 'Total price',
                            controller: total,
                            focusNode: totalFocus,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            paidSoFar == null ? 'Advance paid' : 'Paid so far',
                            style: fieldLabel,
                          ),
                          const SizedBox(height: 6),
                          if (paidSoFar == null)
                            _MoneyField(
                              label: 'Advance paid',
                              controller: advance,
                              focusNode: advanceFocus,
                            )
                          else
                            _MoneyField.readOnly(paidSoFar!),
                        ],
                      ),
                    ),
                  ],
                ),
                if (totalProblem ?? advanceProblem case final problem?) ...[
                  const SizedBox(height: 10),
                  _Problem(problem, onCarbon: true),
                ],
                if (paidSoFar != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Record payments from the order page.',
                    style: fieldLabel,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.fromLTRB(0, 12, 0, 10),
                  child: AppDashedLine(
                    color: Color.fromRGBO(255, 255, 255, 0.3),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BALANCE DUE ON DELIVERY',
                            style: AppTypography.sectionLabel.copyWith(
                              fontSize: 10.5,
                              letterSpacing: 10.5 * 0.09,
                              color: const Color.fromRGBO(255, 255, 255, 0.6),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text('Calculated automatically', style: fieldLabel),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      label: 'Balance due on delivery',
                      child: Text(
                        formatRupees(balance),
                        style: AppTypography.numberLg.copyWith(
                          fontSize: 26,
                          letterSpacing: 26 * -0.03,
                          color: AppPalette.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required TextEditingController this.controller,
    required FocusNode this.focusNode,
  }) : amount = null;

  const _MoneyField.readOnly(double this.amount)
    : label = 'Paid so far',
      controller = null,
      focusNode = null;

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double? amount;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode?.hasFocus ?? false;
    final style = AppTypography.numberMd.copyWith(color: AppPalette.white);
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppPalette.white.withValues(alpha: focused ? 0.1 : 0.07),
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(
          color: AppPalette.white.withValues(alpha: focused ? 0.4 : 0.2),
          width: focused ? 1.5 : 1,
        ),
      ),
      alignment: Alignment.centerLeft,
      child: controller == null
          ? Text(formatRupees(amount!), style: style)
          : Row(
              children: [
                Text('Rs', style: style),
                const SizedBox(width: 6),
                Expanded(
                  child: Semantics(
                    label: label,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [RupeeInputFormatter()],
                      cursorColor: AppPalette.white,
                      style: style,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: '0',
                        hintStyle: style.copyWith(
                          color: AppPalette.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.balance,
    required this.label,
    required this.saving,
    required this.onSave,
  });

  final double balance;
  final String label;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
          13,
          AppSpacing.screenPadding,
          0,
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Balance',
                  style: AppTypography.support.copyWith(
                    fontSize: 10.5,
                    color: AppPalette.ink55,
                  ),
                ),
                Text(
                  formatRupees(balance),
                  style: AppTypography.numberMd.copyWith(
                    letterSpacing: 17 * -0.02,
                    color: AppPalette.carbon,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                label: label,
                isLoading: saving,
                onPressed: onSave,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

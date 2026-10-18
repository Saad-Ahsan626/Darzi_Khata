import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer_activity.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customer_activity_provider.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_row.dart';

/// What was chosen in the customer picker: a saved customer, or to add a new
/// one starting from [newName].
typedef CustomerPick = ({Customer? customer, String? newName});

/// Picks who an order is for, searching by name or phone. Resolves to null
/// when dismissed.
Future<CustomerPick?> showCustomerPicker(
  BuildContext context, {
  required List<Customer> customers,
}) => showModalBottomSheet<CustomerPick>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  sheetAnimationStyle: AnimationStyle(
    duration: AppMotion.sheet,
    curve: AppMotion.curve,
  ),
  builder: (context) => _CustomerPicker(customers: customers),
);

class _CustomerPicker extends ConsumerStatefulWidget {
  const _CustomerPicker({required this.customers});
  final List<Customer> customers;

  @override
  ConsumerState<_CustomerPicker> createState() => _CustomerPickerState();
}

class _CustomerPickerState extends ConsumerState<_CustomerPicker> {
  String _query = '';

  static final _phoneLike = RegExp(r'^[\d\s+\-]+$');

  List<Customer> get _matches {
    final query = _query.trim().toLowerCase();
    final digits = _phoneLike.hasMatch(query) ? phoneDigits(query) : '';
    return [
      for (final customer in widget.customers)
        if (query.isEmpty ||
            customer.name.toLowerCase().contains(query) ||
            (digits.isNotEmpty && phoneDigits(customer.phone).contains(digits)))
          customer,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  void _addNew() {
    final query = _query.trim();
    Navigator.pop<CustomerPick>(context, (
      customer: null,
      newName: _phoneLike.hasMatch(query) ? '' : query,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final activity = ref.watch(customerActivityProvider);
    final matches = _matches;
    final height = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Choose customer',
                        style: AppTypography.title.copyWith(
                          fontSize: 18,
                          letterSpacing: 18 * -0.02,
                          color: AppPalette.carbon,
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'New',
                      icon: Icons.add,
                      variant: AppButtonVariant.outlined,
                      expand: false,
                      onPressed: _addNew,
                    ),
                  ],
                ),
              ),
              if (widget.customers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    AppSpacing.xs,
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() => _query = value),
                    textInputAction: TextInputAction.search,
                    style: AppTypography.body.copyWith(
                      fontSize: 14.5,
                      fontFeatures: AppTypography.tabularFigures,
                      color: AppPalette.carbon,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone',
                      hintStyle: AppTypography.body.copyWith(
                        fontSize: 14.5,
                        color: AppPalette.ink45,
                      ),
                      isDense: true,
                      constraints: const BoxConstraints(
                        minHeight: AppSizing.minHitTarget,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                      fillColor: AppPalette.surfaceSunken,
                      prefixIcon: const Icon(Icons.search, size: 20),
                    ),
                  ),
                ),
              Flexible(
                child: matches.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        child: AppDashedBox(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                widget.customers.isEmpty
                                    ? 'No customers yet'
                                    : 'No customer matches “${_query.trim()}”',
                                textAlign: TextAlign.center,
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppPalette.carbon,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Add them now and the order is linked to '
                                'them straight away.',
                                textAlign: TextAlign.center,
                                style: AppTypography.support.copyWith(
                                  fontWeight: FontWeight.w400,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton(
                                label: 'Add new customer',
                                icon: Icons.person_add_alt_1_outlined,
                                onPressed: _addNew,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.xs,
                          AppSpacing.screenPadding,
                          AppSpacing.lg,
                        ),
                        itemCount: matches.length,
                        separatorBuilder: (context, index) =>
                            const AppDashedLine(),
                        itemBuilder: (context, index) {
                          final customer = matches[index];
                          return CustomerRow(
                            customer: customer,
                            activity:
                                activity[customer.id] ??
                                const CustomerActivity(),
                            onTap: () => Navigator.pop<CustomerPick>(context, (
                              customer: customer,
                              newName: null,
                            )),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

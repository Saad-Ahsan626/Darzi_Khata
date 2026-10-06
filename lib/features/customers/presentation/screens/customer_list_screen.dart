import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer_activity.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customer_activity_provider.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_row.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static final _phoneLike = RegExp(r'^[\d\s+\-]+$');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  /// Opens the new-customer form, carrying over what was searched for.
  void _addFromSearch() {
    final query = _searchQuery.trim();
    final field = _phoneLike.hasMatch(query) ? 'phone' : 'name';
    context.push(
      Uri(path: '/customers/new', queryParameters: {field: query}).toString(),
    );
  }

  List<Customer> _matching(List<Customer> customers) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return customers;
    final digits = _phoneLike.hasMatch(query) ? phoneDigits(query) : '';
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          (customer.urduName?.contains(query) ?? false) ||
          (digits.isNotEmpty && phoneDigits(customer.phone).contains(digits));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);
    final activity = ref.watch(customerActivityProvider);
    final customers = customersAsync.valueOrNull;

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
                          'Customers',
                          style: AppTypography.screenTitle.copyWith(
                            color: AppPalette.carbon,
                          ),
                        ),
                        if (customers != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            _summary(customers, activity),
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
                    message: 'Add customer',
                    child: AppButton(
                      label: 'Add',
                      icon: Icons.add,
                      expand: false,
                      onPressed: () => context.push('/customers/new'),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.lg,
                AppSpacing.screenPadding,
                0,
              ),
              child: _SearchField(
                controller: _searchController,
                enabled: customers?.isNotEmpty ?? false,
                onChanged: (value) => setState(() => _searchQuery = value),
                onClear: _clearSearch,
              ),
            ),
            Expanded(
              child: customersAsync.when(
                loading: () => const Center(child: AppLoading()),
                error: (error, stack) => Center(
                  child: AppFeedback.error(
                    message: "Couldn't open your customers.",
                    actionLabel: 'Try again',
                    onAction: () => ref
                        .read(customersNotifierProvider.notifier)
                        .loadCustomers(),
                  ),
                ),
                data: (customers) => _buildResults(customers, activity),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _summary(
    List<Customer> customers,
    Map<String, CustomerActivity> activity,
  ) {
    if (customers.isEmpty) return 'Nothing saved yet';
    final withBalances = customers
        .where((customer) => (activity[customer.id]?.outstanding ?? 0) > 0)
        .length;
    return [
      '${customers.length} saved',
      if (withBalances > 0) '$withBalances with balances',
    ].join(' · ');
  }

  Widget _buildResults(
    List<Customer> customers,
    Map<String, CustomerActivity> activity,
  ) {
    if (customers.isEmpty) {
      return _NoCustomers(onAdd: () => context.push('/customers/new'));
    }
    final matches = [..._matching(customers)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (matches.isEmpty) {
      return _NoMatches(
        query: _searchQuery.trim(),
        isPhone: _phoneLike.hasMatch(_searchQuery.trim()),
        onClear: _clearSearch,
        onAdd: _addFromSearch,
      );
    }

    // Rows are grouped under the first letter of the name.
    final rows = <Widget>[];
    String? letter;
    for (final customer in matches) {
      final initial = customer.name.trim().characters.first.toUpperCase();
      if (initial != letter) {
        letter = initial;
        rows.add(
          Padding(
            padding: EdgeInsets.only(top: rows.isEmpty ? 22 : 18, bottom: 8),
            child: AppSectionLabel(initial),
          ),
        );
      } else {
        rows.add(const AppDashedLine());
      }
      rows.add(
        CustomerRow(
          customer: customer,
          activity: activity[customer.id] ?? const CustomerActivity(),
          onTap: () => context.push('/customers/${customer.id}'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.screenPadding,
        AppSpacing.xl,
      ),
      children: rows,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
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
        constraints: const BoxConstraints(minHeight: AppSizing.minHitTarget),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
        fillColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? AppPalette.white
              : AppPalette.surfaceSunken,
        ),
        prefixIcon: const Icon(Icons.search, size: 20),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? AppPalette.carbon
              : AppPalette.ink45,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.cancel, size: 20),
                color: AppPalette.ink45,
                onPressed: onClear,
              ),
        border: border(AppPalette.line),
        enabledBorder: border(AppPalette.line),
        disabledBorder: border(AppPalette.line),
        focusedBorder: border(AppPalette.carbon, 2),
      ),
    );
  }
}

class _NoCustomers extends StatelessWidget {
  const _NoCustomers({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      34,
      AppSpacing.screenPadding,
      AppSpacing.xl,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.line),
      ),
      child: Column(
        children: [
          const AppIconTile(
            icon: Icons.person_outline,
            size: 56,
            strong: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No customers yet',
            textAlign: TextAlign.center,
            style: AppTypography.title.copyWith(
              fontSize: 17,
              letterSpacing: 17 * -0.015,
              color: AppPalette.carbon,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Save a customer once and their measurements are reusable on '
            'every future order.',
            textAlign: TextAlign.center,
            style: AppTypography.support.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          AppButton(
            label: 'Add First Customer',
            icon: Icons.add,
            onPressed: onAdd,
          ),
        ],
      ),
    ),
  );
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({
    required this.query,
    required this.isPhone,
    required this.onClear,
    required this.onAdd,
  });

  final String query;
  final bool isPhone;
  final VoidCallback onClear;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      AppSpacing.lg,
      AppSpacing.screenPadding,
      AppSpacing.xl,
    ),
    child: AppDashedBox(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Text(
            'No match for “$query”',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 15.5 * -0.01,
              color: AppPalette.carbon,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Check the ${isPhone ? 'number' : 'spelling'}, or save this as '
            'a new customer.',
            textAlign: TextAlign.center,
            style: AppTypography.support.copyWith(
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Clear search',
                  variant: AppButtonVariant.outlined,
                  onPressed: onClear,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(label: 'Add new', onPressed: onAdd),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

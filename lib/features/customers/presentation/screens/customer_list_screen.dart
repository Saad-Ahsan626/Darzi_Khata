import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_card.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);

    return Scaffold(
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.carbon,
        elevation: 0,
        title: const Text(
          'Customers',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 22,
            color: AppPalette.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Add customer',
            icon: const Icon(
              Icons.person_add_outlined,
              color: AppPalette.white,
            ),
            onPressed: () => context.push('/customers/new'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase();
                });
              },
              style: const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 15,
                color: AppPalette.carbon,
              ),
              decoration: InputDecoration(
                hintText: 'Search name or phone...',
                hintStyle: const TextStyle(
                  color: AppPalette.ink70,
                  fontFamily: AppTypography.fontFamily,
                ),
                prefixIcon: const Icon(Icons.search, color: AppPalette.ink70),
                filled: true,
                fillColor: AppPalette.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: customersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppPalette.carbon),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: AppPalette.carbon),
          ),
        ),
        data: (customers) {
          final filteredCustomers = customers.where((c) {
            final nameMatch = c.name.toLowerCase().contains(_searchQuery);
            final urduMatch =
                c.urduName?.toLowerCase().contains(_searchQuery) ?? false;
            final phoneMatch =
                c.phone
                    ?.replaceAll(' ', '')
                    .contains(_searchQuery.replaceAll(' ', '')) ??
                false;
            return nameMatch || urduMatch || phoneMatch;
          }).toList();

          if (customers.isEmpty) {
            return Center(
              child: AppFeedback(
                title: 'No customers yet',
                message: 'Add your first customer to get started.',
                actionLabel: 'Add customer',
                onAction: () => context.push('/customers/new'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCustomers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final customer = filteredCustomers[index];
              return CustomerCard(customer: customer);
            },
          );
        },
      ),
    );
  }
}

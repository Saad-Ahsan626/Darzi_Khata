import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
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
      backgroundColor: AppColors.tailorChalk,
      appBar: AppBar(
        backgroundColor: AppColors.charcoalThread,
        elevation: 0,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customers',
              style: TextStyle(
                fontFamily: 'Zilla Slab',
                fontSize: 22,
                color: AppColors.tailorChalk,
              ),
            ),
            Text(
              'گاہک',
              style: TextStyle(
                fontFamily: 'Noto Nastaliq Urdu',
                fontSize: 18,
                color: AppColors.brassTape,
              ),
            ),
          ],
        ),
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
                fontFamily: 'Noto Sans',
                fontSize: 15,
                color: AppColors.charcoalThread,
              ),
              decoration: InputDecoration(
                hintText: 'Search name or phone...',
                hintStyle: const TextStyle(
                  color: AppColors.inkMuted,
                  fontFamily: 'Noto Sans',
                ),
                prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted),
                filled: true,
                fillColor: AppColors.tailorChalk,
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
          child: CircularProgressIndicator(color: AppColors.brassTape),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: AppColors.seamRed),
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
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.fabricGrey,
                    style: BorderStyle.none,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'No customers here yet — tap + to create your first one.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Noto Sans',
                    fontSize: 15,
                    color: AppColors.ghost,
                  ),
                ),
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

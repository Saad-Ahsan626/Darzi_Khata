import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
import 'package:tailor_khata/features/customers/presentation/providers/customers_notifier.dart';
import 'package:tailor_khata/features/customers/presentation/widgets/customer_avatar.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';
import 'package:tailor_khata/features/orders/presentation/widgets/order_card.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() =>
      _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersNotifierProvider);
    final ordersAsync = ref.watch(ordersNotifierProvider);

    return customersAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brassTape),
        ),
      ),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (customers) {
        final cList = customers
            .where((c) => c.id == widget.customerId)
            .toList();
        if (cList.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Customer not found')),
          );
        }
        final customer = cList.first;

        return Scaffold(
          backgroundColor: AppColors.tailorChalk,
          appBar: AppBar(
            backgroundColor: AppColors.charcoalThread,
            elevation: 0,
            leading: IconButton(
              icon: const Row(
                children: [
                  Icon(Icons.chevron_left, color: AppColors.brassTape),
                ],
              ),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Customers',
              style: TextStyle(
                fontFamily: 'Noto Sans',
                fontSize: 16,
                color: AppColors.tailorChalk,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppColors.brassTape,
                  size: 20,
                ),
                onPressed: () {
                  context.push(
                    '/customers/${customer.id}/edit',
                    extra: customer,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Header
              Container(
                color: AppColors.charcoalThread,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomerAvatar(
                      customer: customer,
                      size: 64,
                      radius: 16,
                      fontSize: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  customer.name,
                                  style: const TextStyle(
                                    fontFamily: 'Zilla Slab',
                                    fontSize: 20,
                                    color: AppColors.tailorChalk,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (customer.urduName != null &&
                                  customer.urduName!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    customer.urduName!,
                                    style: const TextStyle(
                                      fontFamily: 'Noto Nastaliq Urdu',
                                      fontSize: 18,
                                      color: AppColors.brassTape,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            customer.phone?.isNotEmpty == true
                                ? customer.phone!
                                : 'No phone number',
                            style: const TextStyle(
                              fontFamily: 'Roboto Mono',
                              fontSize: 14,
                              color: AppColors.ghost,
                            ),
                          ),
                          if (customer.address != null &&
                              customer.address!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.diamond,
                                  size: 10,
                                  color: AppColors.brassTape,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    customer.address!,
                                    style: const TextStyle(
                                      fontFamily: 'Noto Sans',
                                      fontSize: 13,
                                      color: AppColors.ghost,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                color: AppColors.tailorChalk,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.brassTape,
                  indicatorWeight: 3,
                  labelColor: AppColors.charcoalThread,
                  unselectedLabelColor: AppColors.inkMuted,
                  labelStyle: const TextStyle(
                    fontFamily: 'Noto Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Noto Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Measurements'),
                    Tab(text: 'Order History'),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Measurements Tab
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.push(
                                '/customers/${customer.id}/measurements',
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.fabricGrey),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.straighten,
                                    color: AppColors.brassTape,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Open Measurement Sheet',
                                          style: TextStyle(
                                            fontFamily: 'Noto Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.charcoalThread,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'No measurements yet — tap to add',
                                          style: TextStyle(
                                            fontFamily: 'Noto Sans',
                                            fontSize: 13,
                                            color: AppColors.ghost,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: AppColors.inkMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brassTape,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                context.push('/orders/new', extra: customer.id);
                              },
                              child: Text(
                                '+ New Order for ${customer.name}',
                                style: const TextStyle(
                                  fontFamily: 'Noto Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Order History Tab
                    ordersAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.brassTape,
                        ),
                      ),
                      error: (e, s) =>
                          Center(child: Text('Error loading orders: $e')),
                      data: (orders) {
                        final customerOrders = orders
                            .where((o) => o.customerId == customer.id)
                            .toList();

                        if (customerOrders.isEmpty) {
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
                                'No orders yet.',
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
                          itemCount: customerOrders.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return OrderCard(order: customerOrders[index]);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

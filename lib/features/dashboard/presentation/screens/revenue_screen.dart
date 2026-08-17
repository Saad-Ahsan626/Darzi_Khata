import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';
import 'package:tailor_khata/features/orders/presentation/providers/orders_notifier.dart';

class RevenueScreen extends ConsumerWidget {
  const RevenueScreen({super.key});

  bool _isSameWeek(DateTime date, DateTime now) {
    // A simple approximation: if the difference is <= 7 days and they are in the same week block
    final int difference = now.difference(date).inDays;
    return difference >= 0 && difference <= 7;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  bool _isSameYear(DateTime a, DateTime b) {
    return a.year == b.year;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.tailorChalk,
      appBar: AppBar(
        backgroundColor: AppColors.charcoalThread,
        elevation: 0,
        leading: IconButton(
          icon: const Row(
            children: [Icon(Icons.chevron_left, color: AppColors.brassTape)],
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Revenue',
              style: TextStyle(
                fontFamily: 'Zilla Slab',
                fontSize: 22,
                color: AppColors.tailorChalk,
              ),
            ),
            Text(
              'آمدنی',
              style: TextStyle(
                fontFamily: 'Noto Nastaliq Urdu',
                fontSize: 18,
                color: AppColors.brassTape,
              ),
            ),
          ],
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brassTape)),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (orders) {
          final now = DateTime.now();

          double thisWeek = 0;
          double thisMonth = 0;
          double thisYear = 0;
          double lifetime = 0;

          // Cash received = advancePaid at createdAt + (total - advance) at deliveredAt
          for (final order in orders) {
            final advance = order.advancePaid;
            final remaining = order.totalAmount - advance;

            // Process advance (paid at creation)
            if (advance > 0) {
              lifetime += advance;
              if (_isSameYear(order.createdAt, now)) {
                thisYear += advance;
                if (_isSameMonth(order.createdAt, now)) {
                  thisMonth += advance;
                  if (_isSameWeek(order.createdAt, now)) {
                    thisWeek += advance;
                  }
                }
              }
            }

            // Process remaining (paid at delivery)
            if (order.status == 'Delivered' && order.deliveredAt != null && remaining > 0) {
              final dDate = order.deliveredAt!;
              lifetime += remaining;
              if (_isSameYear(dDate, now)) {
                thisYear += remaining;
                if (_isSameMonth(dDate, now)) {
                  thisMonth += remaining;
                  if (_isSameWeek(dDate, now)) {
                    thisWeek += remaining;
                  }
                }
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRevenueCard(
                  title: 'THIS WEEK',
                  subtitle: 'Past 7 days',
                  amount: thisWeek,
                  icon: Icons.date_range,
                  color: AppColors.stitchNavy,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 16),
                _buildRevenueCard(
                  title: 'THIS MONTH',
                  subtitle: 'Current calendar month',
                  amount: thisMonth,
                  icon: Icons.calendar_today,
                  color: Colors.white,
                  textColor: AppColors.charcoalThread,
                ),
                const SizedBox(height: 16),
                _buildRevenueCard(
                  title: 'THIS YEAR',
                  subtitle: 'Current calendar year',
                  amount: thisYear,
                  icon: Icons.event,
                  color: Colors.white,
                  textColor: AppColors.charcoalThread,
                ),
                const SizedBox(height: 16),
                _buildRevenueCard(
                  title: 'LIFETIME REVENUE',
                  subtitle: 'Total cash collected',
                  amount: lifetime,
                  icon: Icons.account_balance_wallet,
                  color: AppColors.brassTape,
                  textColor: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required String subtitle,
    required double amount,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    final bool isDark = color != Colors.white;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: AppColors.fabricGrey),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.1) : AppColors.tailorChalk,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : AppColors.brassTape,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Noto Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white70 : AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: 'Roboto Mono',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Noto Sans',
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppColors.ghost,
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

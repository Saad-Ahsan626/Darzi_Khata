import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
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
      backgroundColor: AppPalette.white,
      appBar: AppBar(
        backgroundColor: AppPalette.carbon,
        elevation: 0,
        leading: IconButton(
          icon: const Row(
            children: [Icon(Icons.chevron_left, color: AppPalette.white)],
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
              'Revenue',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 22,
                color: AppPalette.white,
              ),
            ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppPalette.carbon),
        ),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (orders) {
          final now = DateTime.now();

          double thisWeek = 0;
          double thisMonth = 0;
          double thisYear = 0;
          double lifetime = 0;

          // Cash received = advancePaid (summed by order creation date)
          for (final order in orders) {
            final advance = order.advancePaid;

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
                  color: AppPalette.carbon,
                  textColor: AppPalette.white,
                ),
                const SizedBox(height: 16),
                _buildRevenueCard(
                  title: 'THIS MONTH',
                  subtitle: 'Current calendar month',
                  amount: thisMonth,
                  icon: Icons.calendar_today,
                  color: AppPalette.white,
                  textColor: AppPalette.carbon,
                ),
                const SizedBox(height: 16),
                _buildRevenueCard(
                  title: 'THIS YEAR',
                  subtitle: 'Current calendar year',
                  amount: thisYear,
                  icon: Icons.event,
                  color: AppPalette.white,
                  textColor: AppPalette.carbon,
                ),
                const SizedBox(height: 16),
                _buildRevenueCard(
                  title: 'LIFETIME REVENUE',
                  subtitle: 'Total cash collected',
                  amount: lifetime,
                  icon: Icons.account_balance_wallet,
                  color: AppPalette.carbon,
                  textColor: AppPalette.white,
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
    final bool isDark = color != AppPalette.white;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: AppPalette.lineStrong),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppPalette.white.withValues(alpha: 0.1)
                  : AppPalette.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? AppPalette.white : AppPalette.carbon,
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
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? AppPalette.onCarbonMuted : AppPalette.ink70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs ${amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontFeatures: AppTypography.tabularFigures,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: isDark ? AppPalette.onCarbonMuted : AppPalette.ink70,
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

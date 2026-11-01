import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/backup/domain/backup_summary.dart';

String _count(int count, String one, String many) =>
    '$count ${count == 1 ? one : many}';

/// Asks before a backup replaces everything on this device, saying what the
/// backup holds and what is here now. Resolves to true only when confirmed.
Future<bool> showRestoreDialog(
  BuildContext context, {
  required BackupSummary backup,
  required ({int customers, int orders})? current,
}) async {
  final made = DateFormat('d MMM yyyy, h:mm a').format(backup.createdAt);
  final holds =
      '${_count(backup.customers, 'customer', 'customers')} and '
      '${_count(backup.orders, 'order', 'orders')}';
  final here = current == null
      ? 'everything on this device'
      : 'the ${_count(current.customers, 'customer', 'customers')} and '
            '${_count(current.orders, 'order', 'orders')} on this device';
  final hasRecords =
      current == null || current.customers > 0 || current.orders > 0;

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
            const AppIconTile(icon: Icons.settings_backup_restore, size: 50),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Replace everything with this backup?',
              style: AppTypography.title.copyWith(
                fontSize: 19,
                letterSpacing: 19 * -0.02,
                color: AppPalette.carbon,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'The backup from $made has $holds. It replaces $here. This '
              'cannot be undone.',
              style: AppTypography.support.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.55,
                fontFeatures: AppTypography.tabularFigures,
              ),
            ),
            if (hasRecords) ...[
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
                        'Back up the records on this device first if you '
                        'might need them.',
                        style: AppTypography.support.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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
              label: 'Keep current records',
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Replace with backup',
              icon: Icons.settings_backup_restore,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    ),
  );
  return confirmed ?? false;
}

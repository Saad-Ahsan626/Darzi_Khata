import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/error/failures.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer.dart';
import 'package:tailor_khata/features/customers/domain/entities/customer_activity.dart';

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

/// Asks before deleting a customer and everything stored for them. Resolves
/// to true only when the deletion is confirmed.
Future<bool> showDeleteCustomerDialog(
  BuildContext context, {
  required Customer customer,
  required CustomerActivity activity,
}) async {
  String count(int count, String one, String many) =>
      '$count ${count == 1 ? one : many}';
  final removed = [
    'the customer',
    if (activity.measurementProfileCount > 0)
      count(
        activity.measurementProfileCount,
        'measurement profile',
        'measurement profiles',
      ),
    if (activity.orderCount > 0) count(activity.orderCount, 'order', 'orders'),
  ];
  final removedText = removed.length == 1
      ? removed.single
      : '${removed.sublist(0, removed.length - 1).join(', ')} and '
            '${removed.last}';

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
            Text('Delete ${customer.name}?', style: _modalTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This removes $removedText from this device. It cannot be '
              'undone and there is no cloud copy.',
              style: _modalBody,
            ),
            if (activity.outstanding > 0) ...[
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
                        '${formatRupees(activity.outstanding)} outstanding '
                        'will be lost from your records',
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
              label: 'Keep customer',
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

/// Tells the user a save did not go through and that the form is intact.
/// Resolves to true when they choose to try again.
Future<bool> showSaveFailureSheet(
  BuildContext context, {
  required Failure failure,
  required DateTime at,
}) async {
  final retry = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppIconTile(icon: Icons.warning_amber_rounded),
            const SizedBox(height: AppSpacing.lg),
            Text("Couldn't save customer", style: _modalTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "The device storage didn't respond. Nothing was lost — your "
              'entries are still on the form.',
              style: _modalBody,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppPalette.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadii.control),
                border: Border.all(color: AppPalette.line),
              ),
              child: Text(
                '${failure.message} · '
                '${DateFormat('d MMM, h:mm a').format(at)}',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.support.copyWith(
                  fontSize: 11.5,
                  fontFeatures: AppTypography.tabularFigures,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Keep editing',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    label: 'Retry save',
                    icon: Icons.refresh,
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return retry ?? false;
}

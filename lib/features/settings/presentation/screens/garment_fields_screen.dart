import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/measurements/domain/entities/garment_template.dart';

/// The fields each garment is measured by, in the order they are taken.
class GarmentFieldsScreen extends StatelessWidget {
  const GarmentFieldsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          children: [
            Row(
              children: [
                AppBoxedIconButton(
                  icon: Icons.chevron_left,
                  label: 'Back',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(width: 9),
                Text(
                  'Garment fields',
                  style: AppTypography.title.copyWith(
                    fontSize: 18,
                    letterSpacing: 18 * -0.02,
                    color: AppPalette.carbon,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.md,
                0,
                AppSpacing.lg,
              ),
              child: Text(
                'The measurements taken for each garment. A value saved '
                'under a field not listed here still shows, under Other.',
                style: AppTypography.support.copyWith(
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
            for (final garment in GarmentTemplates.all) ...[
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.xs),
                child: _GarmentCard(garment),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _GarmentCard extends StatelessWidget {
  const _GarmentCard(this.garment);
  final GarmentTemplate garment;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          garment.name,
          style: AppTypography.body.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: AppPalette.carbon,
          ),
        ),
        for (final group in garment.groups) ...[
          const SizedBox(height: 10),
          AppSectionLabel(group.label),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              for (final field in group.fields)
                field.optional ? '${field.label} (optional)' : field.label,
            ].join(' · '),
            style: AppTypography.support.copyWith(height: 1.45),
          ),
        ],
      ],
    ),
  );
}

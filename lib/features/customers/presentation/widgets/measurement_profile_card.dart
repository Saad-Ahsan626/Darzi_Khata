import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/measurements/domain/entities/fit_profile.dart';
import 'package:tailor_khata/features/measurements/domain/entities/garment_template.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement.dart';
import 'package:tailor_khata/features/measurements/presentation/measurement_format.dart';

/// A saved measurement profile: garment, fit, when it changed and its key
/// values in the unit the profile is kept in.
class MeasurementProfileCard extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback onTap;

  const MeasurementProfileCard({
    super.key,
    required this.measurement,
    required this.onTap,
  });

  static const _shown = 4;

  /// The first recorded values in the garment's own field order.
  List<(MeasurementField, double)> get _values {
    final data = measurement.measurementData;
    final template = GarmentTemplates.named(
      measurement.garmentType,
    ).including(data.keys);
    return [
      for (final field in template.fields)
        if (data[field.key] case final value?) (field, value),
    ].take(_shown).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formal = measurement.fitProfile == FitProfile.formal;
    final fit = measurement.fitProfile.replaceAll(' Fit', '');
    final updated = DateFormat('d MMM').format(measurement.updatedAt);
    final values = _values;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppPalette.line),
    );

    return Material(
      color: AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              measurement.garmentType,
                              style: AppTypography.body.copyWith(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 15.5 * -0.012,
                                color: AppPalette.carbon,
                              ),
                            ),
                            AppStatusBadge(
                              label: fit,
                              tone: formal
                                  ? AppBadgeTone.olive
                                  : AppBadgeTone.outline,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Updated $updated · ${measurement.unit.name}',
                          style: AppTypography.support.copyWith(
                            fontSize: 11.5,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppPalette.ink45,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: AppDashedLine(),
            ),
            if (values.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text('No values yet', style: AppTypography.support),
              )
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, (field, inches)) in values.indexed)
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: index == 0
                                ? null
                                : const Border(
                                    left: BorderSide(color: AppPalette.line),
                                  ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 11,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field.label.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.micro.copyWith(
                                    fontSize: 9.5,
                                    letterSpacing: 9.5 * 0.06,
                                    color: AppPalette.ink55,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  formatMeasurement(inches, measurement.unit),
                                  style: AppTypography.numberMd.copyWith(
                                    fontSize: 16,
                                    color: AppPalette.carbon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

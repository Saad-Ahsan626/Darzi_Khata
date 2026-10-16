import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/measurements/domain/entities/garment_template.dart';

class GarmentTypeSelector extends StatelessWidget {
  const GarmentTypeSelector({
    super.key,
    required this.selectedGarment,
    required this.onChanged,
  });

  final String selectedGarment;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final garment in GarmentTemplates.all)
        AppSelectionChip(
          label: garment.name,
          selected: garment.name == selectedGarment,
          onPressed: () => onChanged(garment.name),
        ),
    ],
  );
}

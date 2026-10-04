import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';

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
    children: ['Shalwar Kameez', 'Kurta', 'Pant-Coat', 'Sherwani', 'Waistcoat']
        .map(
          (garment) => AppSelectionChip(
            label: garment,
            selected: garment == selectedGarment,
            onPressed: () => onChanged(garment),
          ),
        )
        .toList(),
  );
}

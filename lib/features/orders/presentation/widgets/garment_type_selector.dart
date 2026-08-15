import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/app_colors.dart';

class GarmentTypeSelector extends StatelessWidget {
  final String selectedGarment;
  final ValueChanged<String> onChanged;

  const GarmentTypeSelector({
    super.key,
    required this.selectedGarment,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const garments = [
      'Shalwar Kameez',
      'Kurta',
      'Pant-Coat',
      'Sherwani',
      'Waistcoat',
    ];

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: garments.map((garment) {
        final isSelected = garment == selectedGarment;
        return GestureDetector(
          onTap: () => onChanged(garment),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.brassTape : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.brassTape : AppColors.fabricGrey,
              ),
            ),
            child: Text(
              garment,
              style: TextStyle(
                fontFamily: 'Noto Sans',
                fontSize: 14,
                color: isSelected ? Colors.white : AppColors.charcoalThread,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

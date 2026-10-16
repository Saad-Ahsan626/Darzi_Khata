import 'package:flutter/material.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';

/// One measurement in a profile. Empty fields are outlined with dashes and
/// fields changed since the last save are highlighted.
class MeasurementFieldCard extends StatelessWidget {
  const MeasurementFieldCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.edited,
    required this.onTap,
  });

  final String label;

  /// Already formatted in [unit]; null when nothing is recorded.
  final String? value;
  final String unit;
  final bool edited;
  final VoidCallback onTap;

  static const _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    final empty = value == null;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(13, 12, 10, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.micro.copyWith(
                    fontSize: 10.5,
                    letterSpacing: 10.5 * 0.06,
                    color: edited ? AppPalette.oliveInk : AppPalette.ink55,
                  ),
                ),
                const SizedBox(height: 5),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value ?? '—',
                        style: AppTypography.numberLg.copyWith(
                          fontSize: 21,
                          letterSpacing: 21 * -0.02,
                          color: empty ? AppPalette.ink45 : AppPalette.carbon,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: AppTypography.micro.copyWith(
                          fontSize: 11.5,
                          color: AppPalette.ink55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_outlined,
            size: 16,
            color: edited ? AppPalette.carbon : AppPalette.ink45,
          ),
        ],
      ),
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
      side: empty
          ? BorderSide.none
          : edited
          ? const BorderSide(color: AppPalette.carbon, width: 1.5)
          : const BorderSide(color: AppPalette.line),
    );
    final card = Material(
      color: edited ? AppPalette.oliveFill10 : AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, customBorder: shape, child: content),
    );
    return Semantics(
      button: true,
      label:
          '$label, ${value == null ? 'not recorded' : '$value $unit'}'
          '${edited ? ', changed' : ''}',
      excludeSemantics: true,
      child: empty ? AppDashedBox(radius: _radius, child: card) : card,
    );
  }
}

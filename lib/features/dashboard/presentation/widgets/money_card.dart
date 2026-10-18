import 'package:flutter/material.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';

/// A figure on a [MoneyCard], such as what is outstanding.
class MoneyTile {
  const MoneyTile({required this.label, required this.amount, this.caption});
  final String label;
  final num amount;
  final String? caption;
}

/// The carbon card that leads a money screen: a headline amount and the
/// figures that explain it. Money stays on opaque surfaces.
class MoneyCard extends StatelessWidget {
  const MoneyCard({
    super.key,
    required this.label,
    required this.amount,
    required this.tiles,
    this.trailing,
    this.onTap,
    this.prominent = false,
  });

  final String label;
  final num amount;
  final List<MoneyTile> tiles;

  /// Sits beside the label, such as a month picker.
  final Widget? trailing;
  final VoidCallback? onTap;

  /// The larger size used on Home.
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(prominent ? 22 : 20);
    final amountSize = prominent ? 34.0 : 32.0;
    final content = Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: prominent ? 12 : 10,
          child: const AppTickPattern(color: Color(0x38FFFFFF), spacing: 9),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          label.toUpperCase(),
                          style: AppTypography.sectionLabel.copyWith(
                            fontSize: 10,
                            letterSpacing: 10 * 0.12,
                            color: const Color.fromRGBO(255, 255, 255, 0.58),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatRupees(amount),
                            style: AppTypography.numberLg.copyWith(
                              fontSize: amountSize,
                              height: 1.1,
                              letterSpacing: amountSize * -0.03,
                              color: AppPalette.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                ],
              ),
              SizedBox(height: prominent ? 18 : 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (index, tile) in tiles.indexed) ...[
                      if (index > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _Tile(tile: tile, prominent: prominent),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
    return Material(
      color: AppPalette.carbon,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.tile, required this.prominent});
  final MoneyTile tile;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(prominent ? 13 : 12),
    decoration: BoxDecoration(
      color: AppPalette.glassOnCarbon,
      borderRadius: BorderRadius.circular(prominent ? 14 : 13),
      border: Border.all(color: AppPalette.glassBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tile.label.toUpperCase(),
          style: AppTypography.micro.copyWith(
            fontSize: 9.5,
            letterSpacing: 9.5 * 0.1,
            color: const Color.fromRGBO(255, 255, 255, 0.62),
          ),
        ),
        SizedBox(height: prominent ? 6 : 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatRupees(tile.amount),
            style: AppTypography.numberMd.copyWith(
              fontSize: prominent ? 19 : 17,
              color: AppPalette.white,
            ),
          ),
        ),
        if (tile.caption case final caption?) ...[
          const SizedBox(height: 3),
          Text(
            caption,
            style: AppTypography.support.copyWith(
              fontSize: 11,
              fontFeatures: AppTypography.tabularFigures,
              color: const Color.fromRGBO(255, 255, 255, 0.5),
            ),
          ),
        ],
      ],
    ),
  );
}

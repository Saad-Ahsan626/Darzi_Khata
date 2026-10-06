import 'package:flutter/material.dart';
import '../formatting/app_formats.dart';
import '../theme/design_tokens.dart';

class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: AppTypography.sectionLabel.copyWith(color: AppPalette.ink70),
  );
}

class AppMoneyText extends StatelessWidget {
  const AppMoneyText(this.amount, {super.key, this.large = false, this.color});
  final num amount;
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    formatRupees(amount),
    style: (large ? AppTypography.numberLg : AppTypography.numberMd).copyWith(
      color: color ?? DefaultTextStyle.of(context).style.color,
    ),
  );
}

class AppSeparator extends StatelessWidget {
  const AppSeparator({super.key});
  @override
  Widget build(BuildContext context) => const Divider(height: AppSpacing.xl);
}

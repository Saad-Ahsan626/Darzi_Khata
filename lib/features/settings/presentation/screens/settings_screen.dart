import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tailor_khata/core/app_info.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/auth/presentation/widgets/sewn_button_mark.dart';
import 'package:tailor_khata/features/measurements/domain/entities/garment_template.dart';
import 'package:tailor_khata/features/measurements/domain/entities/measurement_unit.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:tailor_khata/features/settings/presentation/providers/shop_settings_providers.dart';
import 'package:tailor_khata/features/settings/presentation/widgets/settings_sheets.dart';

/// The shop's profile and preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Future<ShopSettings?> Function(BuildContext, ShopSettings) sheet,
    ShopSettings settings,
  ) async {
    final changed = await sheet(context, settings);
    if (changed == null || changed == settings || !context.mounted) return;
    await _save(context, ref, changed, confirm: true);
  }

  Future<void> _save(
    BuildContext context,
    WidgetRef ref,
    ShopSettings settings, {
    bool confirm = false,
  }) async {
    final failure = await saveShopSettings(ref, settings);
    if (!context.mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save the settings. Please try again."),
        ),
      );
    } else if (confirm) {
      showAppToast(context, message: 'Settings saved');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(shopSettingsProvider);
    final settings = settingsAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppPalette.white,
      body: SafeArea(
        bottom: false,
        child: settings == null
            ? Center(
                child: settingsAsync.hasError
                    ? AppFeedback.error(
                        message: "Couldn't open the settings.",
                        actionLabel: 'Try again',
                        onAction: () => ref.invalidate(shopSettingsProvider),
                      )
                    : const AppLoading(),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                children: [
                  Text(
                    'Settings',
                    style: AppTypography.screenTitle.copyWith(
                      color: AppPalette.carbon,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ProfileCard(
                    settings: settings,
                    onEdit: () =>
                        _edit(context, ref, showShopProfileSheet, settings),
                  ),
                  const _Heading('Shop'),
                  _Group(
                    rows: [
                      _Row(
                        label: 'Shop address',
                        value: settings.address.isEmpty
                            ? 'Not set'
                            : settings.address,
                        onTap: () =>
                            _edit(context, ref, showAddressSheet, settings),
                      ),
                      _Row(
                        label: 'Shop timings',
                        value: settings.hasHours
                            ? '${settings.openingTime} — '
                                  '${settings.closingTime}'
                            : 'Not set',
                        onTap: () =>
                            _edit(context, ref, showHoursSheet, settings),
                      ),
                      _Row(
                        label: 'Order number prefix',
                        value: settings.orderPrefix,
                        onTap: () =>
                            _edit(context, ref, showOrderPrefixSheet, settings),
                      ),
                    ],
                  ),
                  const _Heading('Measurements'),
                  _Group(
                    rows: [
                      _Row(
                        label: 'Default unit',
                        detail: 'Used for new profiles',
                        trailing: _UnitToggle(
                          unit: settings.defaultUnit,
                          onChanged: (unit) => _save(
                            context,
                            ref,
                            settings.copyWith(defaultUnit: unit),
                          ),
                        ),
                      ),
                      _Row(
                        label: 'Garment fields',
                        value: '${GarmentTemplates.all.length} garments',
                        onTap: () => context.push('/settings/garments'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _AboutCard(onAbout: () => _showAbout(context)),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: 'Design system preview',
                      icon: Icons.palette_outlined,
                      variant: AppButtonVariant.text,
                      onPressed: () => context.push('/design-preview'),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  void _showAbout(BuildContext context) => showAboutDialog(
    context: context,
    applicationName: appName,
    applicationVersion: 'Version $appVersion',
    applicationIcon: const _Logo(size: 44),
    children: [
      const Text(
        'A ledger for tailoring shops: customers, measurements, orders and '
        'balances. Everything is kept on this device and works without '
        'internet.',
      ),
    ],
  );
}

class _Logo extends StatelessWidget {
  const _Logo({this.size = 52});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AppPalette.carbon,
      borderRadius: BorderRadius.circular(size * 0.29),
    ),
    alignment: Alignment.center,
    child: SewnButtonMark.logo(size: size * 0.85),
  );
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.settings, required this.onEdit});
  final ShopSettings settings;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final shop = settings.shopName;
    final details = [
      if (settings.ownerName.isNotEmpty) settings.ownerName,
      if (settings.phone.isNotEmpty) formatPhone(settings.phone),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppPalette.line),
      ),
      child: Row(
        children: [
          const _Logo(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.isEmpty ? 'Name your shop' : shop,
                  style: AppTypography.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 16 * -0.015,
                    color: shop.isEmpty ? AppPalette.ink55 : AppPalette.carbon,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  details.isEmpty
                      ? 'Add the owner and phone'
                      : details.join(' · '),
                  style: AppTypography.support.copyWith(
                    fontSize: 12,
                    fontFeatures: AppTypography.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton(
            onPressed: onEdit,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 38),
              fixedSize: const Size.fromHeight(38),
              tapTargetSize: MaterialTapTargetSize.padded,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
              textStyle: AppTypography.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 10),
    child: Text(
      label.toUpperCase(),
      style: AppTypography.sectionLabel.copyWith(
        fontSize: 10.5,
        letterSpacing: 10.5 * 0.11,
        color: AppPalette.ink55,
      ),
    ),
  );
}

class _Row {
  const _Row({
    required this.label,
    this.detail,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? detail;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class _Group extends StatelessWidget {
  const _Group({required this.rows});
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.card),
      side: const BorderSide(color: AppPalette.line),
    );
    return Material(
      color: AppPalette.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, row) in rows.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: AppDashedLine(),
              ),
            InkWell(
              onTap: row.onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.label,
                              style: AppTypography.body.copyWith(
                                fontSize: 14,
                                color: AppPalette.carbon,
                              ),
                            ),
                            if (row.detail != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                row.detail!,
                                style: AppTypography.support.copyWith(
                                  fontSize: 11.5,
                                  color: AppPalette.ink55,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (row.value != null)
                        // Up to two-fifths of the row, against its end.
                        Flexible(
                          flex: 2,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.md,
                              ),
                              child: Text(
                                row.value!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.support.copyWith(
                                  fontFeatures: AppTypography.tabularFigures,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ?row.trailing,
                      if (row.onTap != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppPalette.ink45,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.unit, required this.onChanged});
  final MeasurementUnit unit;
  final ValueChanged<MeasurementUnit> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppPalette.surfaceControl,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color.fromRGBO(23, 25, 24, 0.08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in MeasurementUnit.values)
          Semantics(
            selected: option == unit,
            inMutuallyExclusiveGroup: true,
            label: option == MeasurementUnit.inches ? 'Inches' : 'Centimeters',
            child: TextButton(
              onPressed: option == unit ? null : () => onChanged(option),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 32),
                fixedSize: const Size.fromHeight(32),
                tapTargetSize: MaterialTapTargetSize.padded,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: option == unit
                    ? AppPalette.carbon
                    : Colors.transparent,
                foregroundColor: AppPalette.ink55,
                disabledForegroundColor: AppPalette.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                textStyle: AppTypography.body.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: ExcludeSemantics(child: Text(option.code)),
            ),
          ),
      ],
    ),
  );
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.onAbout});
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) => Material(
    color: AppPalette.surfaceSunken,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color.fromRGBO(23, 25, 24, 0.08)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onAbout,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: AppTypography.body.copyWith(
                      fontSize: 13,
                      color: const Color.fromRGBO(23, 25, 24, 0.75),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Version $appVersion · works fully offline',
                    style: AppTypography.support.copyWith(
                      fontSize: 11.5,
                      fontFeatures: AppTypography.tabularFigures,
                      color: AppPalette.ink55,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'About',
              style: AppTypography.body.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppPalette.oliveInk,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

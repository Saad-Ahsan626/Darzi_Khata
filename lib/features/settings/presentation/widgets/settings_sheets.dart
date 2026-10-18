import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';

/// Opens a sheet that edits part of the shop's settings. Resolves to the
/// changed settings, or null when cancelled.
Future<ShopSettings?> _showSheet(
  BuildContext context,
  Widget Function(BuildContext context) builder,
) => showModalBottomSheet<ShopSettings>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  sheetAnimationStyle: AnimationStyle(
    duration: AppMotion.sheet,
    curve: AppMotion.curve,
  ),
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          0,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding,
        ),
        child: builder(context),
      ),
    ),
  ),
);

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.children,
    required this.onSave,
    this.intro,
  });

  final String title;
  final String? intro;
  final List<Widget> children;

  /// Null while the entries cannot be saved.
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: AppTypography.title.copyWith(
          fontSize: 18,
          letterSpacing: 18 * -0.02,
          color: AppPalette.carbon,
        ),
      ),
      if (intro != null) ...[
        const SizedBox(height: 6),
        Text(
          intro!,
          style: AppTypography.support.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
      const SizedBox(height: 18),
      ...children,
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: AppButton(label: 'Save', onPressed: onSave),
          ),
        ],
      ),
    ],
  );
}

// Shop profile

Future<ShopSettings?> showShopProfileSheet(
  BuildContext context,
  ShopSettings settings,
) => _showSheet(context, (context) => _ProfileSheet(settings));

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet(this.settings);
  final ShopSettings settings;

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  static const _maxName = 40;

  late final _shop = TextEditingController(text: widget.settings.shopName);
  late final _owner = TextEditingController(text: widget.settings.ownerName);
  late final _phone = TextEditingController(
    text: phoneDigits(widget.settings.phone),
  );

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _shop.dispose();
    _owner.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// A phone number is optional, but a partial one is not saved.
  String? get _phoneProblem {
    final digits = _phone.text;
    if (digits.isEmpty) return null;
    if (!digits.startsWith('0')) return 'Start the number with 0';
    if (digits.length < 11) {
      return 'Needs 11 digits — ${11 - digits.length} remaining';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: 'Shop profile',
    intro: 'Shown on Home and in the reminders you send to customers.',
    onSave: _phoneProblem != null
        ? null
        : () => Navigator.pop(
            context,
            widget.settings.copyWith(
              shopName: _shop.text.trim(),
              ownerName: _owner.text.trim(),
              phone: _phone.text,
            ),
          ),
    children: [
      AppTextField(
        label: 'Shop name',
        controller: _shop,
        hint: 'e.g. Hassan Tailors',
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        inputFormatters: [LengthLimitingTextInputFormatter(_maxName)],
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: "Owner's name",
        controller: _owner,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        inputFormatters: [LengthLimitingTextInputFormatter(_maxName)],
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: 'Shop phone (optional)',
        controller: _phone,
        kind: AppFieldKind.phone,
        hint: '03xx xxx xxxx',
        errorText: _phoneProblem,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
      ),
    ],
  );
}

// Address

Future<ShopSettings?> showAddressSheet(
  BuildContext context,
  ShopSettings settings,
) => _showSheet(context, (context) => _AddressSheet(settings));

class _AddressSheet extends StatefulWidget {
  const _AddressSheet(this.settings);
  final ShopSettings settings;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  late final _address = TextEditingController(text: widget.settings.address);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: 'Shop address',
    onSave: () => Navigator.pop(
      context,
      widget.settings.copyWith(address: _address.text.trim()),
    ),
    children: [
      AppTextField(
        label: 'Address',
        controller: _address,
        hint: 'e.g. Shop 12, Anarkali Bazaar, Lahore',
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [LengthLimitingTextInputFormatter(120)],
      ),
    ],
  );
}

// Hours

/// `HH:mm`, as hours are stored.
String _stored(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';

TimeOfDay? _parse(String? value) {
  final parts = value?.split(':');
  if (parts == null || parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

Future<ShopSettings?> showHoursSheet(
  BuildContext context,
  ShopSettings settings,
) => _showSheet(context, (context) => _HoursSheet(settings));

class _HoursSheet extends StatefulWidget {
  const _HoursSheet(this.settings);
  final ShopSettings settings;

  @override
  State<_HoursSheet> createState() => _HoursSheetState();
}

class _HoursSheetState extends State<_HoursSheet> {
  late TimeOfDay? _opens = _parse(widget.settings.openingTime);
  late TimeOfDay? _closes = _parse(widget.settings.closingTime);

  Future<void> _pick({required bool opening}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          (opening ? _opens : _closes) ??
          TimeOfDay(hour: opening ? 11 : 21, minute: 0),
      helpText: opening ? 'Shop opens at' : 'Shop closes at',
    );
    if (picked == null || !mounted) return;
    setState(() => opening ? _opens = picked : _closes = picked);
  }

  @override
  Widget build(BuildContext context) {
    final opens = _opens;
    final closes = _closes;
    final same = opens != null && opens == closes;
    final complete = opens != null && closes != null;
    return _SheetFrame(
      title: 'Shop timings',
      intro: 'Added to WhatsApp reminders so customers know when to come.',
      onSave: complete && !same
          ? () => Navigator.pop(
              context,
              widget.settings.copyWith(
                hours: () => (opens: _stored(opens), closes: _stored(closes)),
              ),
            )
          : null,
      children: [
        Row(
          children: [
            Expanded(
              child: _TimeButton(
                label: 'Opens',
                time: opens,
                onTap: () => _pick(opening: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimeButton(
                label: 'Closes',
                time: closes,
                onTap: () => _pick(opening: false),
              ),
            ),
          ],
        ),
        if (same) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Opening and closing times are the same.',
            style: AppTypography.support.copyWith(color: AppPalette.carbon),
          ),
        ],
        if (widget.settings.hasHours) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => Navigator.pop(
                context,
                widget.settings.copyWith(hours: () => null),
              ),
              child: const Text('Remove timings'),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: AppTypography.support),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.schedule, size: 18),
        label: Text(time?.format(context) ?? 'Choose'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: AppTypography.body.copyWith(
            fontFeatures: AppTypography.tabularFigures,
          ),
        ),
      ),
    ],
  );
}

// Order prefix

Future<ShopSettings?> showOrderPrefixSheet(
  BuildContext context,
  ShopSettings settings,
) => _showSheet(context, (context) => _PrefixSheet(settings));

class _PrefixSheet extends StatefulWidget {
  const _PrefixSheet(this.settings);
  final ShopSettings settings;

  @override
  State<_PrefixSheet> createState() => _PrefixSheetState();
}

class _PrefixSheetState extends State<_PrefixSheet> {
  static const _maxLength = 6;

  late final _prefix = TextEditingController(text: widget.settings.orderPrefix);

  @override
  void initState() {
    super.initState();
    _prefix.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _prefix.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefix = _prefix.text.trim();
    final preview = widget.settings.copyWith(orderPrefix: prefix);
    return _SheetFrame(
      title: 'Order number prefix',
      intro:
          'Comes before every order number, including orders already '
          'saved.',
      onSave: prefix.isEmpty ? null : () => Navigator.pop(context, preview),
      children: [
        AppTextField(
          label: 'Prefix',
          controller: _prefix,
          hint: 'e.g. DK-',
          textCapitalization: TextCapitalization.characters,
          errorText: prefix.isEmpty ? 'Enter at least one letter' : null,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
            LengthLimitingTextInputFormatter(_maxLength),
            TextInputFormatter.withFunction(
              (_, value) => value.copyWith(text: value.text.toUpperCase()),
            ),
          ],
        ),
        if (prefix.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Next order: ${preview.orderLabel(widget.settings.nextOrderNumber)}',
            style: AppTypography.support.copyWith(
              fontFeatures: AppTypography.tabularFigures,
              color: AppPalette.carbon,
            ),
          ),
        ],
      ],
    );
  }
}

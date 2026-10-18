import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tailor_khata/core/formatting/app_formats.dart';
import 'package:tailor_khata/core/theme/design_tokens.dart';
import 'package:tailor_khata/core/widgets/app_widgets.dart';
import 'package:tailor_khata/features/orders/domain/entities/order.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_status.dart';
import 'package:tailor_khata/features/orders/domain/entities/order_timing.dart';
import 'package:tailor_khata/features/settings/domain/entities/shop_settings.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link in another app. Resolves to false when nothing opened it.
/// Tests replace it to see the link without leaving the app.
final externalLinkLauncherProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Shop hours such as `11am–9pm`, or null when they are not set.
String? shopTimings(ShopSettings settings) {
  String? time(String? value) {
    final parts = value?.split(':');
    if (parts == null || parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    final at = DateTime(2000, 1, 1, hour, minute);
    return DateFormat(minute == 0 ? 'ha' : 'h:mma').format(at).toLowerCase();
  }

  final opens = time(settings.openingTime);
  final closes = time(settings.closingTime);
  return opens == null || closes == null ? null : '$opens–$closes';
}

/// A message about [order] for the customer to read on WhatsApp: ready for
/// pickup, still in production, or money still owed after delivery.
String reminderMessage({
  required Order order,
  required String customerName,
  required String? orderLabel,
  required ShopSettings settings,
  required DateTime today,
}) {
  final shop = settings.shopName.trim();
  final ordered = orderLabel == null
      ? 'Your ${order.garmentType} order'
      : 'Your ${order.garmentType} order ($orderLabel)';
  final due = order.balance > 0
      ? ' Balance due: ${formatRupees(order.balance)}.'
      : '';
  final timings = shopTimings(settings);
  final hours = timings == null ? '' : ' Shop timings $timings.';
  final greeting = 'Assalam o Alaikum $customerName.';

  if (order.isDelivered) {
    return '$greeting ${formatRupees(order.balance)} is still due on '
        '${ordered.replaceFirst('Your', 'your')}'
        '${shop.isEmpty ? '' : ' from $shop'}. Thank you.';
  }
  if (order.status == OrderStatus.ready) {
    return '$greeting $ordered is ready for pickup'
        '${shop.isEmpty ? '' : ' at $shop'}.$due$hours';
  }
  final progress = switch (order.status) {
    OrderStatus.cutting => 'is being cut',
    OrderStatus.stitching => 'is being stitched',
    _ => 'has been received',
  };
  final expected = order.isOverdue(today)
      ? ' We will let you know as soon as it is ready.'
      : ' Expected delivery: '
            '${DateFormat('d MMM').format(order.deliveryDate)}.';
  return '$greeting $ordered${shop.isEmpty ? '' : ' at $shop'} $progress.'
      '$expected$due';
}

/// A wa.me link that opens a chat with [phone] and [message] typed in, or
/// null without a number to send to.
Uri? whatsAppLink(String? phone, String message) {
  final digits = phoneDigits(phone);
  if (digits.length < 10) return null;
  final international = digits.startsWith('0')
      ? '92${digits.substring(1)}'
      : digits;
  return Uri.https('wa.me', '/$international', {'text': message});
}

/// Shows the reminder text and opens WhatsApp with it typed in. Nothing is
/// sent from this app.
Future<void> showReminderSheet(
  BuildContext context, {
  required String customerName,
  required String? phone,
  required String message,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  sheetAnimationStyle: AnimationStyle(
    duration: AppMotion.sheet,
    curve: AppMotion.curve,
  ),
  builder: (context) => _ReminderSheet(
    customerName: customerName,
    phone: phone,
    message: message,
  ),
);

class _ReminderSheet extends ConsumerStatefulWidget {
  const _ReminderSheet({
    required this.customerName,
    required this.phone,
    required this.message,
  });

  final String customerName;
  final String? phone;
  final String message;

  @override
  ConsumerState<_ReminderSheet> createState() => _ReminderSheetState();
}

class _ReminderSheetState extends ConsumerState<_ReminderSheet> {
  late final _controller = TextEditingController(text: widget.message);
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _text => _controller.text.trim();

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text));
    if (!mounted) return;
    Navigator.pop(context);
    showAppToast(context, message: 'Message copied');
  }

  Future<void> _open(Uri link) async {
    var opened = false;
    try {
      opened = await ref.read(externalLinkLauncherProvider)(link);
    } on Exception {
      opened = false;
    }
    if (!mounted) return;
    if (opened) {
      Navigator.pop(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't open WhatsApp. Copy the text instead."),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = formatPhone(widget.phone);
    final link = whatsAppLink(widget.phone, _text);
    final sectionLabel = AppTypography.sectionLabel.copyWith(
      fontSize: 10.5,
      letterSpacing: 10.5 * 0.09,
      color: AppPalette.ink55,
    );
    final messageStyle = AppTypography.body.copyWith(
      fontSize: 13.5,
      fontWeight: FontWeight.w400,
      height: 1.6,
      fontFeatures: AppTypography.tabularFigures,
      color: const Color.fromRGBO(23, 25, 24, 0.85),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            0,
            AppSpacing.screenPadding,
            AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const AppIconTile(
                    icon: Icons.chat_bubble_outline,
                    size: 44,
                    strong: false,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Open WhatsApp reminder',
                          style: AppTypography.title.copyWith(
                            fontSize: 17,
                            letterSpacing: 17 * -0.018,
                            color: AppPalette.carbon,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phone.isEmpty
                              ? 'To ${widget.customerName}'
                              : 'To ${widget.customerName} · $phone',
                          style: AppTypography.support.copyWith(
                            fontSize: 12,
                            fontFeatures: AppTypography.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('MESSAGE PREVIEW', style: sectionLabel),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceSunken,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_editing)
                      TextField(
                        controller: _controller,
                        autofocus: true,
                        minLines: 3,
                        maxLines: 8,
                        style: messageStyle,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      )
                    else
                      Text(_text, style: messageStyle),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppPalette.line),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _editing = !_editing),
                        icon: Icon(
                          _editing ? Icons.check : Icons.edit_outlined,
                          size: 15,
                        ),
                        label: Text(_editing ? 'Done editing' : 'Edit message'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppPalette.ink70,
                          padding: EdgeInsets.zero,
                          textStyle: AppTypography.body.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  border: Border.all(color: AppPalette.lineStrong),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 17,
                      color: AppPalette.ink70,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        link == null
                            ? 'No phone number is saved for '
                                  '${widget.customerName}. Copy the text to '
                                  'send it another way.'
                            : 'Tailor Khata opens WhatsApp with this text '
                                  'ready. You still have to press send there '
                                  '— nothing is sent from this app.',
                        style: AppTypography.support.copyWith(
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: AppButton(
                      label: 'Copy text',
                      variant: AppButtonVariant.outlined,
                      onPressed: _text.isEmpty ? null : _copy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 7,
                    child: ElevatedButton(
                      onPressed: link == null || _text.isEmpty
                          ? null
                          : () => _open(link),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Open WhatsApp',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Icon(Icons.north_east, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

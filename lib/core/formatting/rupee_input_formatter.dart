import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _grouped = NumberFormat('#,##0', 'en');
final _nonDigits = RegExp(r'\D');

/// Whole rupees with thousands separators as they are typed, such as
/// `12,500`. The cursor stays after the same digit.
class RupeeInputFormatter extends TextInputFormatter {
  const RupeeInputFormatter({this.maxDigits = 9});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text
        .replaceAll(_nonDigits, '')
        .replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.length > maxDigits) return oldValue;
    final text = digits.isEmpty ? '' : _grouped.format(int.parse(digits));

    final cursor = newValue.selection.end;
    var digitsBefore = cursor < 0 || cursor > newValue.text.length
        ? digits.length
        : newValue.text.substring(0, cursor).replaceAll(_nonDigits, '').length;
    if (digitsBefore > digits.length) digitsBefore = digits.length;
    var offset = 0;
    for (var seen = 0; offset < text.length && seen < digitsBefore; offset++) {
      if (text[offset] != ',') seen++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Text for an amount field, such as `12,500`. Empty for nothing.
String rupeesInputText(num? amount) =>
    amount == null ? '' : _grouped.format(amount.round());

/// The rupees in text written by [RupeeInputFormatter], or null when empty.
int? parseRupees(String text) => int.tryParse(text.replaceAll(_nonDigits, ''));

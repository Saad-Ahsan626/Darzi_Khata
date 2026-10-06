import 'package:intl/intl.dart';

/// Rupees with thousands separators, such as `Rs 12,500`.
String formatRupees(num amount) =>
    'Rs ${NumberFormat('#,##0.##', 'en').format(amount)}';

/// The digits of a phone number. A leading country code 92 becomes 0, so
/// `+92 300 4128876` and `0300 4128876` give the same digits.
String phoneDigits(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
  return digits.startsWith('92') ? '0${digits.substring(2)}' : digits;
}

/// A phone number grouped for reading, such as `0300 412 8876`.
String formatPhone(String? phone) {
  final digits = phoneDigits(phone);
  if (digits.length <= 4) return digits;
  if (digits.length <= 7) {
    return '${digits.substring(0, 4)} ${digits.substring(4)}';
  }
  return '${digits.substring(0, 4)} ${digits.substring(4, 7)} '
      '${digits.substring(7)}';
}

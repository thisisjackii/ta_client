import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RupiahInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp('[^0-9]'), '');

    // If empty, return empty text
    if (digitsOnly.isEmpty) return TextEditingValue.empty;

    // Parse digits safely
    final number = int.parse(digitsOnly);
    final formatted = _formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

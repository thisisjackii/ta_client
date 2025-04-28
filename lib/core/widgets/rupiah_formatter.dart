import 'package:flutter/services.dart';
import 'package:ta_client/core/utils/calculations.dart';

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue,) {
    // Remove non-digits
    final digitsOnly = newValue.text.replaceAll(RegExp('[^0-9]'), '');

    // If empty, return empty text
    if (digitsOnly.isEmpty) return TextEditingValue.empty;

    // Parse digits safely
    final number = int.parse(digitsOnly);
    final formatted = formatToRupiah(number.toDouble());

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

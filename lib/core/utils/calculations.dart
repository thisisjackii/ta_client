// lib/core/utils/calculations.dart
import 'package:intl/intl.dart';

double clampAllocation(double value, double totalOthers) =>
    value.clamp(0.0, 100.0 - totalOthers);

double parseRupiah(String value) =>
    double.tryParse(value.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

String formatToRupiah(double value) {
  final formatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  return formatter.format(value);
}

String formatMonths(double value) => '${value.toInt()} Bulan';
String formatPercent(double value) => '${value.toInt()}%';

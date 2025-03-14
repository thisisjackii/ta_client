// lib/features/create/view/widgets/transaction_type_toggle.dart
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

class TransactionTypeToggle extends StatelessWidget {

  const TransactionTypeToggle({
    required this.selectedIndex,
    required this.onToggle,
    super.key,
  });
  final int selectedIndex;
  final OnToggle onToggle;

  @override
  Widget build(BuildContext context) {
    return ToggleSwitch(
      minWidth: MediaQuery.of(context).size.width,
      cornerRadius: 10,
      activeBgColors: const [
        [Colors.blue, Colors.blueAccent],
        [Colors.red, Colors.redAccent],
      ],
      activeFgColor: Colors.white,
      inactiveBgColor: Colors.grey[300],
      inactiveFgColor: Colors.black87,
      initialLabelIndex: selectedIndex,
      totalSwitches: 2,
      labels: const ['Pemasukan', 'Pengeluaran'],
      radiusStyle: true,
      onToggle: onToggle,
    );
  }
}

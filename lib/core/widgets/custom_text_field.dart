import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    required this.label,
    required this.onChanged,
    super.key,
    this.isObscured = false,
    this.keyboardType,
  });

  final String label;
  final bool isObscured;
  final TextInputType? keyboardType;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isObscured,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
      onChanged: onChanged,
    );
  }
}

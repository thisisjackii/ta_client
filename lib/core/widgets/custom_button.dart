import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({required this.label, this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }
}

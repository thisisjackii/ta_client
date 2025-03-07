// lib/core/widgets/custom_text_field.dart
import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    required this.label,
    this.onChanged,
    this.icons,
    this.suffixType = SuffixType.none,
    super.key,
    this.isObscured = false,
    this.keyboardType,
  });

  final String label;
  final IconData? icons;
  final bool isObscured;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final SuffixType suffixType;

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

enum SuffixType { none, eye, camera }

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isObscured;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueGrey),
        ),
        prefixIcon: widget.icons != null
            ? Opacity(
          opacity: 0.3,
          child: Icon(widget.icons),
        )
            : null,
        hintText: widget.label,
        hintStyle: const TextStyle(
          fontSize: 12,         // Custom font size
          color: Colors.grey,   // Custom color
        ),
        suffixIcon: _buildSuffixIcon(),
      ),
      onChanged: widget.onChanged,
    );
  }

  Widget? _buildSuffixIcon() {
    switch (widget.suffixType) {
      case SuffixType.eye: // Obscure text toggle (password field)
        return IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility : Icons.visibility_off,
            color: _isObscured ? Colors.grey : Colors.blue,
          ),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        );
      case SuffixType.camera: // Camera icon
        return IconButton(
          icon: const Icon(Icons.camera_alt, color: Colors.black26),
          onPressed: () {
            print('Camera clicked at this moment');
          },
        );
      case SuffixType.none: // No suffix icon
      default:
        return null;
    }
  }
}

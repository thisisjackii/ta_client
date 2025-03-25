// lib/core/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SuffixType { none, eye, camera }

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    required this.label,
    this.onChanged,
    this.icons,
    this.suffixType = SuffixType.none,
    super.key,
    this.isObscured = false,
    this.keyboardType,
    this.controller,
    this.inputFormatters,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.maxLengthEnforcement,
    this.validator,
  });

  final String label;
  final IconData? icons;
  final bool isObscured;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final SuffixType suffixType;
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final String? Function(String?)? validator;

  @override

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isObscured;
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      obscureText: _isObscured,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      maxLengthEnforcement: widget.maxLengthEnforcement,
      validator: widget.validator,
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
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        suffixIcon: _buildSuffixIcon(),
      ),
      onChanged: widget.onChanged,
    );
  }

  Widget? _buildSuffixIcon() {
    switch (widget.suffixType) {
      case SuffixType.eye:
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
      case SuffixType.camera:
        return IconButton(
          icon: const Icon(Icons.camera_alt, color: Colors.black26),
          onPressed: () {
            print('Camera clicked at this moment');
          },
        );
      case SuffixType.none:
        return null;
    }
  }
}

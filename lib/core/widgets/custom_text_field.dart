import 'package:flutter/material.dart';


class CustomTextField extends StatefulWidget {
  const CustomTextField({
    required this.label,
    required this.onChanged,
    required this.icons,
    super.key,
    this.isObscured = false,
    this.keyboardType,
  });

  final String label;
  final IconData icons;
  final bool isObscured;
  final TextInputType? keyboardType;
  final void Function(String) onChanged;

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}


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
        prefixIcon: Opacity(
          opacity: 0.3,
          child: Icon(widget.icons),
        ),
        hintText: widget.label,
        suffixIcon: widget.isObscured
            ? IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility : Icons.visibility_off,
            color: _isObscured ? Colors.grey : Colors.blue,
          ),
          onPressed: () {
            setState(() {
              _isObscured = !_isObscured;
            });
          },
        )
            : null,
      ),
      onChanged: widget.onChanged,
    );
  }
}

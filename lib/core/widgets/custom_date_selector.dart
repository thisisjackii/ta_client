import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateSelector extends StatefulWidget {

  const CustomDateSelector({
    Key? key,
    required this.label,
    this.icons,
    required this.onDateSelected,
  }) : super(key: key);
  final String label;
  final IconData? icons;
  final Function(String) onDateSelected;

  @override
  _CustomDateSelectorState createState() => _CustomDateSelectorState();
}

class _CustomDateSelectorState extends State<CustomDateSelector> {
  DateTime? _selectedDate;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Future<void> _pickDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      widget.onDateSelected(_dateFormat.format(pickedDate));
    }
  }

  Widget? _buildSuffixIcon() {
    if (_selectedDate != null) {
      return IconButton(
        icon: const Icon(Icons.clear, color: Colors.grey),
        onPressed: () {
          setState(() {
            _selectedDate = null;
          });
          widget.onDateSelected('');
        },
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () => _pickDate(context), // Use onTap to open the date picker
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
        hintText: _selectedDate != null
            ? _dateFormat.format(_selectedDate!)
            : widget.label,
        hintStyle: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
        suffixIcon: _buildSuffixIcon(),
      ),
      style: const TextStyle(fontSize: 18, color: Colors.black),
    );
  }
}

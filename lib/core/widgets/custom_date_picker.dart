import 'package:flutter/material.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';

class CustomDatePicker extends StatefulWidget {
  const CustomDatePicker({
    required this.label,
    required this.isDatePicker,
    super.key,
  });

  final String label;
  final bool isDatePicker;

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  final TextEditingController _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (widget.isDatePicker) {
          // Show Date Picker
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            setState(() {
              _controller.text = '${pickedDate.year}-${pickedDate.month}-${pickedDate.day}';
            });
          }
        } else {
          // Show Time Picker
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (pickedTime != null) {
            setState(() {
              _controller.text = pickedTime.format(context); // Formats time to a readable string
            });
          }
        }
      },
      child: AbsorbPointer( // Prevents the keyboard from appearing
        child: CustomTextField(
          label: widget.label,
          onChanged: (value) {}, // No direct input allowed
          keyboardType: TextInputType.none, // Disables keyboard input
        ),
      ),
    );
  }
}

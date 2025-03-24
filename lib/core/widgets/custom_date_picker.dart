// lib/core/widgets/custom_date_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/widgets/custom_text_field.dart';

class CustomDatePicker extends StatefulWidget {
  const CustomDatePicker({
    required this.label,
    required this.isDatePicker,
    super.key,
    this.onDateChanged,
    this.onTimeChanged,
    this.initialDate,
    this.initialTime,
  });

  final String label;
  final bool isDatePicker;
  final void Function(DateTime)? onDateChanged;
  final void Function(TimeOfDay)? onTimeChanged;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isDatePicker && widget.initialDate != null) {
      _controller.text = DateFormat('dd/MM/yyyy').format(widget.initialDate!);
    } else if (!widget.isDatePicker && widget.initialTime != null) {
      // Using addPostFrameCallback to ensure context is ready for formatting.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _controller.text = widget.initialTime!.format(context);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (widget.isDatePicker) {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: widget.initialDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (pickedDate != null) {
            setState(() {
              _controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
            });
            if (widget.onDateChanged != null) {
              widget.onDateChanged?.call(pickedDate);
            }
          }
        } else {
          final pickedTime = await showTimePicker(
            context: context,
            initialTime: widget.initialTime ?? TimeOfDay.now(),
          );
          if (pickedTime != null) {
            setState(() {
              _controller.text = pickedTime.format(context);
            });
            if (widget.onTimeChanged != null) {
              widget.onTimeChanged?.call(pickedTime);
            }
          }
        }
      },
      child: AbsorbPointer(
        child: CustomTextField(
          controller: _controller,
          label: widget.label,
          onChanged: (value) {},
          keyboardType: TextInputType.none,
        ),
      ),
    );
  }
}

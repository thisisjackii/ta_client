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
    this.validator,
    this.selectedDate,
    this.isEnabled = true,
  });

  final String label;
  final bool isDatePicker;
  final void Function(DateTime)? onDateChanged;
  final void Function(TimeOfDay)? onTimeChanged;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final String? Function(String?)? validator;

  final DateTime? selectedDate;
  final bool isEnabled;

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setInitialText();
  }

  @override
  void didUpdateWidget(covariant CustomDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _setInitialText(); // Sync text with updated selectedDate
  }

  void _setInitialText() {
    final effectiveDate = widget.selectedDate ?? widget.initialDate;

    if (widget.isDatePicker && effectiveDate != null) {
      _controller.text = DateFormat('dd/MM/yyyy').format(effectiveDate);
    } else if (!widget.isDatePicker && widget.initialTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialTime!.format(context);
      });
    }
  }

  Future<void> _handleTap() async {
    if (!widget.isEnabled) return;

    if (widget.isDatePicker) {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: widget.selectedDate ?? widget.initialDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (pickedDate != null) {
        _controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
        widget.onDateChanged?.call(pickedDate);
      }
    } else {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: widget.initialTime ?? TimeOfDay.now(),
      );
      if (pickedTime != null) {
        _controller.text = pickedTime.format(context);
        widget.onTimeChanged?.call(pickedTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      builder: (FormFieldState<String> field) {
        return GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
            ignoring: true, // Let GestureDetector handle taps
            child: CustomTextField(
              controller: _controller,
              label: widget.label,
              onChanged: (_) {},
              keyboardType: TextInputType.none,
              validator: (_) => field.errorText,
              isEnabled: widget.isEnabled,
            ),
          ),
        );
      },
    );
  }
}

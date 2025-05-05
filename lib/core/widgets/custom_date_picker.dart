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
    this.validator,
    this.selectedDate,
    this.isEnabled = true, // this toggles enable/disable
    this.firstDate,
    this.lastDate,
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

  // New parameters for bounding the date picker
  final DateTime? firstDate;
  final DateTime? lastDate;

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
  void didUpdateWidget(covariant CustomDatePicker old) {
    super.didUpdateWidget(old);
    _setInitialText();
  }

  void _setInitialText() {
    final dt = widget.selectedDate ?? widget.initialDate;
    if (widget.isDatePicker && dt != null) {
      _controller.text = DateFormat('dd/MM/yyyy').format(dt);
    } else if (!widget.isDatePicker && widget.initialTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialTime!.format(context);
      });
    }
  }

  Future<void> _handleTap() async {
    if (!widget.isEnabled) return;

    if (widget.isDatePicker) {
      final picked = await showDatePicker(
        context: context,
        initialDate:
            widget.selectedDate ?? widget.initialDate ?? DateTime.now(),
        firstDate: widget.firstDate ?? DateTime(2000),
        lastDate: widget.lastDate ?? DateTime(2100),
      );
      if (picked != null) {
        _controller.text = DateFormat('dd/MM/yyyy').format(picked);
        widget.onDateChanged?.call(picked);
      }
    } else {
      final t = await showTimePicker(
        context: context,
        initialTime: widget.initialTime ?? TimeOfDay.now(),
      );
      if (t != null && mounted) {
        _controller.text = t.format(context);
        widget.onTimeChanged?.call(t);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      builder: (field) {
        return GestureDetector(
          onTap: _handleTap,
          behavior: HitTestBehavior.opaque,
          child: IgnorePointer(
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

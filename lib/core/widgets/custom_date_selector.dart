// lib/core/widgets/custom_date_selector.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateSelector extends StatefulWidget {
  const CustomDateSelector({
    required this.label,
    required this.onDateSelected,
    super.key,
    this.icons,
    this.initialDate,
    this.validator,
  });

  final String label; // Placeholder text when no date is selected
  final IconData? icons;
  final void Function(DateTime?) onDateSelected; // Callback takes DateTime?
  final DateTime? initialDate; // To pre-fill the selector
  final String? Function(DateTime?)?
  validator; // Validator for FormField integration

  @override
  _CustomDateSelectorState createState() => _CustomDateSelectorState();
}

class _CustomDateSelectorState extends State<CustomDateSelector> {
  DateTime? _selectedDate;
  final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  // Sync with widget.initialDate if it changes externally due to parent rebuild
  @override
  void didUpdateWidget(CustomDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate &&
        widget.initialDate != _selectedDate) {
      // Only update if the new initialDate is different from the current _selectedDate
      // This prevents resetting user's pick if parent rebuilds for other reasons
      // but the intended initialDate hasn't actually changed for this field.
      if (mounted) {
        setState(() {
          _selectedDate = widget.initialDate;
        });
      }
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 5),
      ), // Allow selecting up to 5 years in future, adjust as needed
    );
    if (pickedDate != null) {
      if (mounted) {
        setState(() {
          _selectedDate = pickedDate;
        });
        widget.onDateSelected(pickedDate);
        field.didChange(pickedDate); // Update FormField state
      }
    }
  }

  Widget? _buildSuffixIcon(FormFieldState<DateTime> field) {
    if (_selectedDate != null) {
      return IconButton(
        icon: const Icon(Icons.clear, color: Colors.grey),
        onPressed: () {
          if (mounted) {
            setState(() {
              _selectedDate = null;
            });
            widget.onDateSelected(null);
            field.didChange(null);
          }
        },
      );
    }
    return null; // No icon if no date is selected
  }

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: _selectedDate,
      validator: widget.validator,
      builder: (FormFieldState<DateTime> field) {
        // This state sync might be redundant if didUpdateWidget handles it well
        // if (_selectedDate != field.value && field.value != widget.initialDate) {
        //   WidgetsBinding.instance.addPostFrameCallback((_) {
        //     if (mounted && _selectedDate != field.value) {
        //       setState(() {
        //         _selectedDate = field.value;
        //       });
        //     }
        //   });
        // }

        return InkWell(
          onTap: () => _pickDate(context, field),
          child: InputDecorator(
            decoration: InputDecoration(
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueGrey),
              ),
              prefixIcon: widget.icons != null
                  ? Opacity(opacity: 0.3, child: Icon(widget.icons))
                  : null,
              // Label text behavior for InputDecorator is a bit different from TextField's hintText
              // We use the child Text widget to display the date or placeholder.
              // labelText: widget.label, // Using child Text instead for better control
              errorText: field.errorText,
              suffixIcon: _buildSuffixIcon(field),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
              ), // Adjust padding
            ),
            child: Text(
              _selectedDate != null
                  ? _displayFormat.format(_selectedDate!)
                  : widget.label, // Show placeholder if no date
              style: TextStyle(
                fontSize: 16, // Match typical TextField font size
                color: _selectedDate != null
                    ? Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.color // Default text color
                    : Theme.of(context).hintColor, // Placeholder color
              ),
            ),
          ),
        );
      },
    );
  }
}

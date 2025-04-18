import 'package:flutter/material.dart';

class DropdownItem {
  DropdownItem({required this.label, required this.color, this.icon});
  final String label;
  final IconData? icon;
  final Color color;
}

class CustomDropdownField extends StatefulWidget {
  const CustomDropdownField({
    required this.items,
    required this.selectedValue,
    required this.onChanged,
    this.label,
    super.key,
  });
  final List<DropdownItem> items;
  final String? selectedValue;
  final void Function(DropdownItem) onChanged;
  final String? label;

  @override
  _CustomDropdownFieldState createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField> {
  late String? currentSelected;

  @override
  void initState() {
    super.initState();
    currentSelected = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              widget.label!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        Container(
          padding: EdgeInsets.zero,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey,
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('-- Pilih Jenis Akun --'),
                    value: currentSelected,
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (value) {
                      setState(() {
                        currentSelected = value;
                        final selectedItem = widget.items.firstWhere(
                          (item) => item.label == value,
                        );
                        widget.onChanged(selectedItem);
                      });
                    },
                    items: widget.items.map((item) {
                      return DropdownMenuItem<String>(
                        value: item.label,
                        child: Row(
                          children: [
                            if (item.icon != null) ...[
                              Icon(item.icon, color: item.color, size: 20),
                              const SizedBox(width: 8),
                            ],
                            Text(item.label),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

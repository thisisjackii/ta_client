import 'package:flutter/material.dart';

class DropdownItem {
  final String label;
  final IconData icon;
  final Color color;

  DropdownItem({required this.label, required this.icon, required this.color});
}

class CustomDropdownField extends StatefulWidget {
  final List<DropdownItem> items;
  final String? selectedValue;
  final Function(DropdownItem) onChanged;

  const CustomDropdownField({
    Key? key,
    required this.items,
    required this.selectedValue,
    required this.onChanged,
  }) : super(key: key);

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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey, // Underline color
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
                hint: Text('-- Pilih Jenis Akun --'),
                value: currentSelected,
                icon: Icon(Icons.arrow_drop_down),
                onChanged: (value) {
                  setState(() {
                    currentSelected = value!;
                    final selectedItem = widget.items.firstWhere((item) => item.label == value);
                    widget.onChanged(selectedItem);
                  });
                },
                items: widget.items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item.label,
                    child: Row(
                      children: [
                        Icon(item.icon, color: item.color, size: 20),
                        SizedBox(width: 8),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the selected date
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:ta_client/app/routes/routes.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    required this.isSelectionMode,
    required this.selectedMonth,
    required this.onMonthChanged,
    super.key,
  });
  final ValueNotifier<bool> isSelectionMode;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  // Helper to add or subtract months safely.
  DateTime _changeMonth(DateTime date, int change) {
    var newYear = date.year;
    var newMonth = date.month + change;
    if (newMonth > 12) {
      newYear += (newMonth - 1) ~/ 12;
      newMonth = ((newMonth - 1) % 12) + 1;
    } else if (newMonth < 1) {
      newYear -= ((1 - newMonth) ~/ 12) + 1;
      newMonth = 12 - ((1 - newMonth) % 12);
    }
    return DateTime(newYear, newMonth);
  }

  Future<void> _pickMonth(BuildContext context) async {
    final selected = await showMonthPicker(
      context: context,
      initialDate: widget.selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      widget.onMonthChanged(DateTime(selected.year, selected.month));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Format the displayed month as 'MMM yyyy' (e.g., Jan 2025)
    final monthYearText = DateFormat('MMM yyyy').format(widget.selectedMonth);

    return AppBar(
      automaticallyImplyLeading: false, // Removes default leading button
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isSelectionMode.value == true)
            const Text(
              'Selection Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed: () {
                // Subtract one month
                final newMonth = _changeMonth(widget.selectedMonth, -1);
                widget.onMonthChanged(newMonth);
              },
            ),
            GestureDetector(
              onTap: () => _pickMonth(context),
              child: Text(
                monthYearText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Adjust text color if needed
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: () {
                // Add one month
                final newMonth = _changeMonth(widget.selectedMonth, 1);
                widget.onMonthChanged(newMonth);
              },
            ),
          ],
        ],
      ),
      actions: [
        if (widget.isSelectionMode.value)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              widget.isSelectionMode.value = false; // Exit selection mode
            },
          )
        else
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {
                  // Handle settings action
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt_rounded),
                onPressed: () {
                  Navigator.pushNamed(context, Routes.filter);
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu),
                onSelected: (value) {
                  if (value == 'statistic') {
                    Navigator.pushNamed(context, Routes.statistik);
                  } else if (value == 'download_pdf') {
                    // Handle Download PDF action (leave blank for now)
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'statistic',
                    child: Text('Statistic'),
                  ),
                  const PopupMenuItem(
                    value: 'download_pdf',
                    child: Text('Download PDF File ...'),
                  ),
                ],
              )

            ],
          ),
      ],
    );
  }
}

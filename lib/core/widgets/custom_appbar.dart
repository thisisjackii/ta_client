// lib/core/widgets/custom_appbar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/widgets/pdf_viewer.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    required this.isSelectionMode,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.onFilterChanged, // New callback to send filter criteria upward.
    required this.onShowDoubleEntryRecap,
    required this.filterCriteria,
    super.key,
  });
  final ValueNotifier<bool> isSelectionMode;
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<Map<String, dynamic>?> onFilterChanged;
  final VoidCallback onShowDoubleEntryRecap;
  final Map<String, dynamic>? filterCriteria;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  _CustomAppBarState createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final String _infoPdfUrl =
      'https://drive.google.com/uc?export=download&id=1wHMt7tr4AnWQeikogczo1ayBh646g3Zl';
  @override
  Widget build(BuildContext context) {
    final monthYearText = DateFormat('MMM yyyy').format(widget.selectedMonth);

    return AppBar(
      backgroundColor: AppColors.greyBackground,
      automaticallyImplyLeading: false,
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
                  color: Colors.black,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.navigate_next),
              onPressed: () {
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
              widget.isSelectionMode.value = false;
            },
          )
        else
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {
                  if (_infoPdfUrl == 'YOUR_DIRECT_PDF_LINK_HERE' ||
                      _infoPdfUrl.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tautan PDF informasi belum diatur.'),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => PdfViewer(
                        pdfUrl: _infoPdfUrl,
                        title: 'Panduan Pengguna', // Or any relevant title
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt_rounded),
                onPressed: () async {
                  final args = {
                    'month': widget.selectedMonth,
                    'criteria': widget.onFilterChanged,
                    'filterCriteria': widget
                        .filterCriteria, // you'll need to pass filterCriteria into CustomAppBar
                  };
                  final result = await Navigator.pushNamed(
                    context,
                    Routes.filter,
                    arguments: args,
                  );
                  if (result != null && result is Map<String, dynamic>) {
                    widget.onFilterChanged(result);
                  }
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.menu),
                onSelected: (value) {
                  if (value == 'statistic') {
                    Navigator.pushNamed(context, Routes.statistik);
                  } else if (value == 'show_double_entry_recap') {
                    widget.onShowDoubleEntryRecap();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'statistic',
                    child: Text('Statistic'),
                  ),
                  const PopupMenuItem(
                    value: 'show_double_entry_recap',
                    child: Text('Lihat Double Entry'),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  // Helper to safely add or subtract months.
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
}

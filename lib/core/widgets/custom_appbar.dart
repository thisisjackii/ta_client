import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the selected date

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  late String titleText; // Title text that will dynamically change

  @override
  void initState() {
    super.initState();
    // Initialize with the current date
    titleText = DateFormat.yMMMd().format(DateTime.now());
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000), // Earliest date allowed
      lastDate: DateTime(2100), // Latest date allowed
    );

    if (selectedDate != null) {
      setState(() {
        // Update the title to the selected date
        titleText = DateFormat.yMMMd().format(selectedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // Removes default leading button
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
            onPressed: () {
              // Handle navigate back action
            },
          ),
          GestureDetector(
            onTap: () => _selectDate(context), // Show date picker on tap
            child: Text(
              ' $titleText ',
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
              // Handle navigate forward action
            },
          ),
        ],
      ),
      actions: [
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
                // Handle notifications action
              },
            ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                // Handle account action
              },
            ),
          ],
        ),
      ],
    );
  }
}
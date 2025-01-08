import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDashboardItem {
  final String title;
  final String description;
  final DateTime date;
  final String category;
  final String subcategory;
  final String amount;

  CustomDashboardItem({
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    required this.subcategory,
    required this.amount,
  });
}

class GroupedListViewExample extends StatelessWidget {
  final List<CustomDashboardItem> items = [
    CustomDashboardItem(
        title: 'Component 1',
        description: 'Description 1',
        date: DateTime(2025, 1, 15),
        category: 'Category 1',
        subcategory: 'Subcategory 1',
        amount: 'Rp. 1.500.000'),
    CustomDashboardItem(
        title: 'Component 2',
        description: 'Description 2',
        date: DateTime(2025, 1, 15),
        category: 'Category 2',
        subcategory: 'Subcategory 2',
        amount: 'Rp. 500.000'),
    CustomDashboardItem(
        title: 'Component 1',
        description: 'Description 3',
        date: DateTime(2025, 1, 16),
        category: 'Category 1',
        subcategory: 'Subcategory 2',
        amount: 'Rp. 25.000'),
    CustomDashboardItem(
        title: 'Component 1',
        description: 'Description 4',
        date: DateTime(2025, 1, 17),
        category: 'Category 1',
        subcategory: 'Subcategory 2',
        amount: 'Rp. 12.000'),
    CustomDashboardItem(
        title: 'Component 2',
        description: 'Description 5',
        date: DateTime(2025, 1, 17),
        category: 'Category 2',
        subcategory: 'Subcategory 1',
        amount: 'Rp. 40.000'),
  ];

  @override
  Widget build(BuildContext context) {
    // Group items by date
    final groupedItems = <DateTime, List<CustomDashboardItem>>{};
    for (var item in items) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      groupedItems.putIfAbsent(date, () => []).add(item);
    }

    final groupedKeys = groupedItems.keys.toList()..sort();

    return ListView.builder(
      itemCount: groupedKeys.length,
      itemBuilder: (context, index) {
        final date = groupedKeys[index];
        final itemsForDate = groupedItems[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Padding(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // Aligns components to left, center, and right
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          _formatDate(date),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            border:
                                Border.all(width: 2.0, color: Colors.black26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: 8.0, left: 8.0),
                            child: Text(
                              _dayName(date),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Text(
                          _formatMonth(date),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Rp. 1.500.000',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.green),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Rp. 1.200.000',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            // List of items for this date
            ...itemsForDate.map((item) {
              return Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                decoration: BoxDecoration(
                    color: Colors.white,
                    // border: Border.all(width: 2.0, color: Colors.black26),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          offset: const Offset(
                            2.0,
                            2.0,
                          ),
                          blurRadius: 2.0,
                          spreadRadius: 1)
                    ]),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.category,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                            SizedBox(height: 4,),
                            Text(
                              item.subcategory,
                              style: const TextStyle(
                                  fontSize: 8, color: Colors.grey),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            SizedBox(height: 4,),
                            Text(
                              item.description,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          item.amount,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ]),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}';
  }

  String _dayName(DateTime date) {
    final dayName = DateFormat('EEE').format(date);
    return '$dayName';
  }

  String _formatMonth(DateTime date) {
    return '${date.month} / ${date.year}';
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}

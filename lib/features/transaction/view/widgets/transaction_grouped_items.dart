// lib/features/transaction/view/widgets/transaction_grouped_items.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';

class TransactionGroupedItemsWidget extends StatelessWidget {
  const TransactionGroupedItemsWidget({
    required this.items,
    required this.isSelectionMode,
    super.key,
  });
  final List<Transaction> items;
  final ValueNotifier<bool> isSelectionMode;

  @override
  Widget build(BuildContext context) {
    // Group items by date
    final groupedItems = <DateTime, List<Transaction>>{};
    final sortedItems = items..sort((a, b) => b.date.compareTo(a.date));
    for (final item in sortedItems) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      groupedItems.putIfAbsent(date, () => []).add(item);
    }
    final groupedKeys = groupedItems.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: groupedKeys.length,
      itemBuilder: (context, index) {
        final date = groupedKeys[index];
        final itemsForDate = groupedItems[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(date),
            ...itemsForDate.map((item) => _buildTransaction(context, item)),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${date.day}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.black26),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      DateFormat('EEE').format(date),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${date.month} / ${date.year}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Optionally, display totals or other summary info here.
          const SizedBox(),
        ],
      ),
    );
  }

  Widget _buildTransaction(BuildContext context, Transaction item) {
    return GestureDetector(
      onLongPress: () {
        isSelectionMode.value = true;
      },
      onTap: () {
        if (!isSelectionMode.value) {
          Navigator.pushNamed(context, Routes.viewTransaction, arguments: item);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(2, 2),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.categoryName.length > 10
                        ? '${item.categoryName.substring(0, 10)}...'
                        : item.categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subcategoryName.length > 10
                        ? '${item.subcategoryName.substring(0, 10)}...'
                        : item.subcategoryName,
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.accountType.length > 15
                        ? '${item.accountType.substring(0, 15)}...'
                        : item.accountType,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description.length > 10
                        ? '${item.description.substring(0, 10)}...'
                        : item.description,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              Text(
                formatToRupiah(item.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

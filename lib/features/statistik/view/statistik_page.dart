import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:flutter/material.dart' hide BoxDecoration, BoxShadow;
import 'package:flutter_inset_shadow/flutter_inset_shadow.dart';

class StatisticPieChart extends StatefulWidget {
  const StatisticPieChart({super.key});

  static Widget create() {
    return const StatisticPieChart();
  }

  @override
  _StatisticPieChartState createState() => _StatisticPieChartState();
}

class _StatisticPieChartState extends State<StatisticPieChart> {
  String selectedType = 'Aset';
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFBFDFF),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text(
                  'Statistik',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _pickMonth,
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(
                DateFormat.yMMMM().format(selectedMonth),
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          DropdownButton<String>(
            value: selectedType,
            items: ['Aset', 'Liabilitas', 'Pemasukan', 'Pengeluaran']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  selectedType = value;
                });
              }
            },
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is DashboardLoaded) {
                    return state.items.isEmpty
                        ? const Center(
                      child: Text(
                        'No Data',
                        style: TextStyle(color: Colors.black),
                      ),
                    )
                        : _buildPieChart(state.items);
                  } else if (state is DashboardError) {
                    return Center(child: Text('Error: ${state.errorMessage}'));
                  }
                  return const Center(
                    child: Text(
                      'No Data',
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                },
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildPieChart(List<Transaction> transactions) {
    // Filter transactions by selected type
    final filteredTransactions = transactions.where((t) {
      final isSameMonth = t.date.year == selectedMonth.year &&
          t.date.month == selectedMonth.month;
      return t.type == selectedType && isSameMonth;
    }).toList();


    if (filteredTransactions.isEmpty) {
      return const Center(
        child: Text(
          'No Data',
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    // Group filtered transactions by category
    final categoryMap = <String, double>{};
    for (var transaction in filteredTransactions) {
      categoryMap.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    // Calculate total amount for percentage calculation
    final double totalAmount =
        categoryMap.values.fold(0, (sum, amount) => sum + amount);

    // Generate pie chart sections with percentages
    final List<PieChartSectionData> sections = categoryMap.entries.map((entry) {
      final double percentage = (entry.value / totalAmount) * 100;

      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        // Show percentage
        color: _getCategoryColor(entry.key),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    Offset distance = Offset(2,2);
    double blur = 4.0;

    return Column(
      children: [
        SizedBox(
          height: 200, // Adjust as needed
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16), // Spacing
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                blurRadius: blur,
                offset: -distance,
                color: Colors.white,
                inset: true
              ),
              BoxShadow(
                  blurRadius: blur,
                  offset: distance,
                  color: Color(0xFFA7A9AF),
                  inset: true
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categoryMap.entries.map((entry) {
                final double percentage = (entry.value / totalAmount) * 100;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.key} (${percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),


      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.yellow,
      Colors.teal,
    ];
    return colors[category.hashCode % colors.length];
  }

  void _pickMonth() async {
    final picked = await showMonthPicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (picked != null) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }


}

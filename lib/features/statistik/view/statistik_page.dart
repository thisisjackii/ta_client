import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFBFDFF),
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text(
              'Statistik',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            )
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
                        )) // Show "No Data" if empty
                      : _buildPieChart(state.items);
                } else if (state is DashboardError) {
                  return Center(child: Text('Error: ${state.errorMessage}'));
                }
                return Center(
                  child: Text(
                    'No Data',
                    style: TextStyle(
                        color: Colors.black), // Set text color to black
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Transaction> transactions) {
    // Filter transactions by selected type
    final filteredTransactions =
        transactions.where((t) => t.type == selectedType).toList();

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
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: categoryMap.entries.map((entry) {
            final double percentage = (entry.value / totalAmount) * 100;

            return Row(
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
                const SizedBox(width: 4),
                Text(
                  '${entry.key} (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            );
          }).toList(),
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
}

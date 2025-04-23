// lib/features/budgeting/view/budgeting_allocation_page.dart

import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/constants/category_mapping.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingAllocation extends StatelessWidget {
  const BudgetingAllocation({super.key});

  static bool _isExpenseCategory(String key) {
    const expenseKeys = {
      'Tabungan',
      'Makanan & Minuman',
      'Hadiah & Donasi',
      'Transportasi',
      'Kesehatan & Medis',
      'Perawatan Pribadi & Pakaian',
      'Hiburan & Rekreasi',
      'Pendidikan & Pembelajaran',
      'Kewajiban Finansial (pinjaman, pajak, asuransi)',
      'Perumahan dan Kebutuhan Sehari-hari',
    };
    return expenseKeys.contains(key);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      builder: (context, state) {
        final expenseEntries = categoryMapping.entries
            .where((e) => _isExpenseCategory(e.key))
            .toList();

        final values = state.allocationValues;
        final selectedSubs = state.selectedSubExpenses;
        final selectedCats = state.selectedCategories;

        ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
            snackBarController;

        // total % used so far
        final totalUsed = values.values.fold<double>(0, (sum, v) => sum + v);

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.budgetingTitle),
            backgroundColor: AppColors.primary,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.padding),
            children: [
              const Text(
                AppStrings.allocationHeader,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.smallPadding),
              const Text(
                AppStrings.allocationSubtitle,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: AppDimensions.smallPadding),

              // For each expense category:
              ...expenseEntries.map((entry) {
                final category = entry.key;
                final subItems = entry.value;
                final curr = values[category] ?? 0.0;
                final isSelected = selectedCats.contains(category);

                // sum of others
                final usedByOthers = values.entries
                    .where((e) => e.key != category)
                    .fold<double>(0, (s, e) => s + e.value);
                // how much this one can still take
                final remain = (100.0 - usedByOthers).clamp(0.0, 100.0);

                return Card(
                  margin:
                      const EdgeInsets.only(bottom: AppDimensions.smallPadding),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.smallPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // header row
                        Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                context.read<BudgetingBloc>().add(
                                      ToggleAllocationCategory(
                                        category: category,
                                        isSelected: val ?? false,
                                      ),
                                    );
                              },
                            ),
                            const SizedBox(width: AppDimensions.smallPadding),
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      isSelected ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                            Text(
                              '${curr.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppDimensions.smallPadding),

                        // stacked slider for fill + remaining overlay + thumb
                        SizedBox(
                          height: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // full grey track
                              FlutterSlider(
                                values: [0],
                                min: 0,
                                max: 100,
                                disabled: true,
                                handler: FlutterSliderHandler(
                                    decoration: const BoxDecoration()),
                                trackBar: FlutterSliderTrackBar(
                                  activeTrackBar:
                                      BoxDecoration(color: Colors.grey[300]),
                                  inactiveTrackBar:
                                      BoxDecoration(color: Colors.grey[300]),
                                ),
                              ),

                              // filled portion
                              FlutterSlider(
                                values: [curr],
                                min: 0,
                                max: 100,
                                disabled: true,
                                handler: FlutterSliderHandler(
                                    decoration: const BoxDecoration()),
                                trackBar: const FlutterSliderTrackBar(
                                  activeTrackBar:
                                      BoxDecoration(color: AppColors.primary),
                                  inactiveTrackBar:
                                      BoxDecoration(color: Colors.transparent),
                                ),
                              ),

                              // remaining overlay from right
                              if (remain < 100)
                                Positioned.fill(
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerRight,
                                    widthFactor: (100 - remain) / 100,
                                    child: Container(
                                        color: Colors.black.withOpacity(0.1)),
                                  ),
                                ),

                              // interactive thumb
                              FlutterSlider(
                                values: [curr],
                                min: 0,
                                max: 100,
                                disabled: !isSelected,
                                handler: FlutterSliderHandler(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black26),
                                    color: Colors.white,
                                  ),
                                ),
                                trackBar: const FlutterSliderTrackBar(
                                  activeTrackBar:
                                      BoxDecoration(color: Colors.transparent),
                                  inactiveTrackBar:
                                      BoxDecoration(color: Colors.transparent),
                                ),
                                onDragging: (handlerIndex, lower, upper) {
                                  final raw = (lower as num).toDouble();
                                  final newVal = raw.clamp(0.0, remain);

                                  // show warning if they try to exceed remainder
                                  if (raw > remain &&
                                      snackBarController == null) {
                                    snackBarController =
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            '⚠️ Total alokasi tidak boleh melebihi 100%'),
                                        backgroundColor: Colors.redAccent,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    snackBarController!.closed
                                        .then((_) => snackBarController = null);
                                  }

                                  context.read<BudgetingBloc>().add(
                                        UpdateAllocationValue(
                                            id: category, value: newVal),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),

                        // sub-items: only if category is selected
                        if (isSelected) ...[
                          const SizedBox(height: AppDimensions.smallPadding),
                          ...subItems.map((sub) {
                            final isChecked =
                                selectedSubs[category]?.contains(sub) ?? false;
                            return CheckboxListTile(
                              value: isChecked,
                              title: Text(sub),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) {
                                context.read<BudgetingBloc>().add(
                                      ToggleExpenseSubItem(
                                        allocationId: category,
                                        subItem: sub,
                                        isSelected: val ?? false,
                                      ),
                                    );
                              },
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),

              // total card
              Card(
                color: AppColors.greyBackground,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        AppStrings.totalAllocation,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text('${totalUsed.toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.smallPadding),
              const Text(
                'Perhitungan anggaran dalam penelitian ini merujuk pada standar yang ditetapkan oleh Kapoor et al. (2015), yang didasarkan pada data dari lembaga statistik Amerika.',
                style: TextStyle(fontSize: 8, color: Colors.grey),
              ),

              const SizedBox(height: AppDimensions.padding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () => Navigator.pushNamed(
                      context, Routes.budgetingAllocationExpense),
                  child: const Text(AppStrings.save),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

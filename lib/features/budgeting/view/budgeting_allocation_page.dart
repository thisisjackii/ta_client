// lib/features/budgeting/view/budgeting_allocation_page.dart

import 'package:another_xlider/another_xlider.dart';
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

class BudgetingAllocation extends StatefulWidget {
  const BudgetingAllocation({super.key});

  @override
  _BudgetingAllocationState createState() => _BudgetingAllocationState();
}

class _BudgetingAllocationState extends State<BudgetingAllocation>
    with RouteAware {
  // local copy of slider positions to force UI bounce-back
  final Map<String, double> _localValues = {};

  // single controller to prevent repeats
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
      _snackBarController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // initialize local values from bloc state once
    if (_localValues.isEmpty) {
      final blocState = context.read<BudgetingBloc>().state;
      _localValues.addAll(blocState.allocationValues);
    }
  }

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
        final allocationData = categoryMapping.entries
            .where((e) => _isExpenseCategory(e.key))
            .toList();
        final selectedCategories = state.selectedCategories;
        final totalAllocation = state.allocationValues.values.fold(
          0.toDouble(),
          (sum, v) => sum + v,
        );

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

              // One card per expense category
              ...allocationData.map((entry) {
                final category = entry.key;

                // use local value if present, else fallback to bloc state
                final currentValue = _localValues[category] ??
                    state.allocationValues[category] ??
                    0.0;

                final isSelected = selectedCategories.contains(category);
                final sliderEnabled = isSelected;

                // compute max so total ≤ 100%
                final othersSum = state.allocationValues.entries
                    .where((e) => e.key != category)
                    .fold(0, (sum, e) => sum + e.value.toInt());
                final maxForCat = (100 - othersSum).clamp(0.0, 100.0);

                return Card(
                  margin:
                      const EdgeInsets.only(bottom: AppDimensions.smallPadding),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.smallPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                context.read<BudgetingBloc>().add(
                                      ToggleAllocationCategory(
                                        category: category,
                                        isSelected: val!,
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
                              '${currentValue.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? Colors.black : Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        // Slider with clamp + bounce-back
                        FlutterSlider(
                          values: [currentValue],
                          max: 100,
                          min: 0,
                          disabled: !sliderEnabled,
                          onDragging: (handlerIndex, lowerValue, upperValue) {
                            final attempt = (lowerValue as num).toDouble();
                            final clamped = attempt.clamp(0.0, maxForCat);

                            if (attempt > maxForCat &&
                                _snackBarController == null) {
                              _snackBarController =
                                  ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '⚠️ Total alokasi tidak boleh melebihi 100%',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              _snackBarController!.closed
                                  .then((_) => _snackBarController = null);
                            }

                            // update local for immediate UI bounce-back
                            setState(() {
                              _localValues[category] = clamped.toDouble();
                            });

                            // dispatch to bloc
                            context.read<BudgetingBloc>().add(
                                  UpdateAllocationValue(
                                    id: category,
                                    value: clamped.toDouble(),
                                  ),
                                );
                          },
                          onDragCompleted:
                              (handlerIndex, lowerValue, upperValue) {
                            final finalVal =
                                (lowerValue as num).toDouble().clamp(
                                      0.0,
                                      maxForCat,
                                    );
                            // ensure local also respects clamp
                            setState(() {
                              _localValues[category] = finalVal.toDouble();
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Total allocation summary
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${totalAllocation.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () {
                    final total = state.allocationValues.values
                        .fold<double>(0, (s, v) => s + v);
                    if (total == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '⚠️ Pilih minimal 1 kategori terlebih dahulu',
                          ),
                        ),
                      );
                      return;
                    } else if (total < 100) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('⚠️ Total alokasi harus mencapai 100%'),
                        ),
                      );
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      Routes.budgetingAllocationExpense,
                    );
                  },
                  child: const Text(
                    AppStrings.save,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

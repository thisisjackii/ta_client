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
  final Map<String, double> _localValues = {};
  final Map<String, TextEditingController> _controllers = {};
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _snackBarController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
        final total = state.allocationValues.values.fold<double>(
          0,
          (sum, v) => sum + v,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              AppStrings.budgetingTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.greyBackground,
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
                final cat = entry.key;
                final current =
                    _localValues[cat] ?? state.allocationValues[cat] ?? 0.0;
                final enabled = state.selectedCategories.contains(cat);
                final othersSum = state.allocationValues.entries
                    .where((e) => e.key != cat)
                    .fold(0.toDouble(), (s, e) => s + e.value);
                final maxForCat = (100.0 - othersSum).clamp(0.0, 100.0);

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: AppDimensions.smallPadding,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.smallPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: enabled,
                              onChanged: (v) =>
                                  context.read<BudgetingBloc>().add(
                                    ToggleAllocationCategory(
                                      category: cat,
                                      isSelected: v!,
                                    ),
                                  ),
                            ),
                            const SizedBox(width: AppDimensions.smallPadding),
                            Expanded(
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: enabled ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                            // Editable percent field:
                            SizedBox(
                              width: 50,
                              child: TextFormField(
                                controller: _controllers[cat] =
                                    TextEditingController(
                                      text: '${current.toStringAsFixed(0)}',
                                    ),
                                enabled: enabled,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: InputDecoration(
                                  suffixText: '%',
                                  isDense: true,
                                ),
                                onFieldSubmitted: (str) {
                                  final p = (double.tryParse(str) ?? 0).clamp(
                                    0.0,
                                    maxForCat,
                                  );
                                  setState(() {
                                    _localValues[cat] = p;
                                    _controllers[cat]!.text = p.toStringAsFixed(
                                      0,
                                    );
                                  });
                                  context.read<BudgetingBloc>().add(
                                    UpdateAllocationValue(id: cat, value: p),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        FlutterSlider(
                          values: [current],
                          min: 0,
                          max: 100,
                          disabled: !enabled,
                          onDragging: (__, lower, ___) {
                            final attempt = (lower as num).toDouble();
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
                                    ),
                                  );
                              _snackBarController!.closed.then(
                                (_) => _snackBarController = null,
                              );
                            }
                            setState(() {
                              _localValues[cat] = clamped;
                              _controllers[cat]!.text = clamped.toStringAsFixed(
                                0,
                              );
                            });
                            context.read<BudgetingBloc>().add(
                              UpdateAllocationValue(id: cat, value: clamped),
                            );
                          },
                          onDragCompleted: (__, lower, ___) {
                            final finalVal = (lower as num).toDouble().clamp(
                              0.0,
                              maxForCat,
                            );
                            setState(() {
                              _localValues[cat] = finalVal;
                              _controllers[cat]!.text = finalVal
                                  .toStringAsFixed(0);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Total summary
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
                      Text('${total.toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.smallPadding),
              const Text(
                'Perhitungan anggaran dalam penelitian ini merujuk pada standar yang ditetapkan oleh Kapoor et al. (2015)…',
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
                    if (total == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            '⚠️ Pilih minimal 1 kategori terlebih dahulu',
                          ),
                        ),
                      );
                      return;
                    }
                    if (total < 100) {
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

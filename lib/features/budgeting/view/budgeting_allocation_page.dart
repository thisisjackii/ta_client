// lib/features/budgeting/view/budgeting_allocation_page.dart
import 'package:another_xlider/another_xlider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
// For typing
import 'package:ta_client/features/budgeting/view/widgets/budgeting_criteria.dart';
import 'package:ta_client/features/profile/bloc/profile_bloc.dart';
import 'package:ta_client/features/profile/bloc/profile_state.dart'
    as ProfileBlocState;

class BudgetingAllocationPage extends StatefulWidget {
  const BudgetingAllocationPage({super.key});

  @override
  _BudgetingAllocationPageState createState() =>
      _BudgetingAllocationPageState();
}

class _BudgetingAllocationPageState extends State<BudgetingAllocationPage> {
  final Map<String, TextEditingController> _percentageControllers = {};
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _snackBarController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers from BLoC state in case of rebuild or coming back to page
    _updateControllersFromBlocState(context.read<BudgetingBloc>().state);
  }

  void _updateControllersFromBlocState(BudgetingState blocState) {
    blocState.expenseAllocationPercentages.forEach((categoryId, value) {
      if (_percentageControllers[categoryId] == null) {
        _percentageControllers[categoryId] = TextEditingController();
      }
      // Check if the current text is different to avoid unnecessary updates and cursor jumps
      if (_percentageControllers[categoryId]!.text !=
          value.toStringAsFixed(0)) {
        _percentageControllers[categoryId]!.text = value.toStringAsFixed(0);
      }
    });
  }

  @override
  void dispose() {
    _percentageControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;
    var occupationGroup = OccupationGroup.pekerja; // Default
    if (profileState is ProfileBlocState.ProfileLoadSuccess) {
      occupationGroup = getOccupationGroup(profileState.user.occupationName);
    }

    return BlocConsumer<BudgetingBloc, BudgetingState>(
      listenWhen: (prev, curr) =>
          curr.error != null ||
          curr.infoMessage != null ||
          prev.expenseAllocationPercentages !=
              curr.expenseAllocationPercentages, // Listen for percentage changes
      listener: (context, state) {
        if (state.error != null) {
          _snackBarController?.close();
          _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
          context.read<BudgetingBloc>().add(BudgetingClearError());
        }
        if (state.infoMessage != null) {
          _snackBarController?.close();
          _snackBarController = ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.infoMessage!)));
          context.read<BudgetingBloc>().add(BudgetingClearError());
        }
        // Update text controllers if BLoC state changes (e.g. after loading existing budget)
        _updateControllersFromBlocState(state);
      },
      buildWhen: (prev, curr) =>
          prev.loading != curr.loading ||
          prev.expenseCategorySuggestions != curr.expenseCategorySuggestions ||
          prev.selectedExpenseCategoryIds != curr.selectedExpenseCategoryIds ||
          prev.expenseAllocationPercentages !=
              curr.expenseAllocationPercentages,
      builder: (context, state) {
        if (state.loading && state.expenseCategorySuggestions.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.budgetingTitle)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final totalAllocatedPercentage = state
            .expenseAllocationPercentages
            .values
            .fold<double>(0, (sum, v) => sum + v);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              AppStrings.budgetingTitle,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.greyBackground,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
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
              const SizedBox(height: AppDimensions.padding),

              if (state.expenseCategorySuggestions.isEmpty && !state.loading)
                const Center(
                  child: Text('Tidak ada saran kategori pengeluaran.'),
                ),

              ...state.expenseCategorySuggestions.map((suggestion) {
                final categoryId = suggestion.id;
                final categoryName = suggestion.name;
                final isSelected = state.selectedExpenseCategoryIds.contains(
                  categoryId,
                );
                final currentPercentage =
                    state.expenseAllocationPercentages[categoryId] ?? 0.0;

                // Ensure controller exists
                _percentageControllers.putIfAbsent(
                  categoryId,
                  () => TextEditingController(
                    text: currentPercentage.toStringAsFixed(0),
                  ),
                );
                // Update controller text if BLoC state changed it (e.g. undo or external update)
                if (_percentageControllers[categoryId]!.text !=
                    currentPercentage.toStringAsFixed(0)) {
                  _percentageControllers[categoryId]!.text = currentPercentage
                      .toStringAsFixed(0);
                  // Move cursor to end after programmatic text change
                  _percentageControllers[categoryId]!
                      .selection = TextSelection.fromPosition(
                    TextPosition(
                      offset: _percentageControllers[categoryId]!.text.length,
                    ),
                  );
                }

                final sumOfOtherSelectedPercentages = state
                    .selectedExpenseCategoryIds
                    .where((id) => id != categoryId)
                    .fold(
                      0.toDouble(),
                      (sum, id) =>
                          sum + (state.expenseAllocationPercentages[id] ?? 0.0),
                    );

                final maxPercentageForThisCategory =
                    (100.0 - sumOfOtherSelectedPercentages).clamp(0.0, 100.0);

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
                              value: isSelected,
                              onChanged: (selected) {
                                context.read<BudgetingBloc>().add(
                                  BudgetingToggleExpenseCategory(
                                    categoryId: categoryId,
                                    isSelected: selected ?? false,
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: Text(
                                categoryName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 70, // Increased width for text field
                              child: TextFormField(
                                controller: _percentageControllers[categoryId],
                                enabled: isSelected,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                decoration: const InputDecoration(
                                  suffixText: '%',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onFieldSubmitted: (valueStr) {
                                  final p = (double.tryParse(valueStr) ?? 0.0)
                                      .clamp(0.0, maxPercentageForThisCategory);
                                  context.read<BudgetingBloc>().add(
                                    BudgetingUpdateExpenseCategoryPercentage(
                                      categoryId: categoryId,
                                      percentage: p,
                                    ),
                                  );
                                  // Controller text will be updated by BlocListener
                                },
                                // Optional: onChanged to update BLoC more frequently, but can be noisy
                              ),
                            ),
                          ],
                        ),
                        if (isSelected) // Only show slider if category is selected
                          FlutterSlider(
                            values: [
                              currentPercentage.clamp(0.0, 100.0),
                            ], // Ensure value is within slider's own min/max
                            min: 0,
                            max:
                                100, // Slider max is always 100, actual clamp happens on value
                            disabled: !isSelected,
                            onDragging: (handlerIndex, lowerValue, upperValue) {
                              final attemptedValue = (lowerValue as num)
                                  .toDouble();
                              final clampedValue = attemptedValue.clamp(
                                0.0,
                                maxPercentageForThisCategory,
                              );

                              // Update text field while dragging
                              _percentageControllers[categoryId]?.text =
                                  clampedValue.toStringAsFixed(0);
                              _percentageControllers[categoryId]
                                  ?.selection = TextSelection.fromPosition(
                                TextPosition(
                                  offset: _percentageControllers[categoryId]!
                                      .text
                                      .length,
                                ),
                              );

                              // Check against Kapoor suggestions
                              final kapoorRange =
                                  kapoorMinMax[occupationGroup]?[categoryName]; // Use categoryName for lookup
                              if (kapoorRange != null &&
                                  (clampedValue < kapoorRange[0] ||
                                      clampedValue > kapoorRange[1])) {
                                if (_snackBarController == null) {
                                  _snackBarController =
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Saran alokasi untuk "$categoryName": ${kapoorRange[0]}% - ${kapoorRange[1]}%',
                                          ),
                                          backgroundColor: Colors.orangeAccent,
                                        ),
                                      );
                                  _snackBarController!.closed.then(
                                    (_) => _snackBarController = null,
                                  );
                                }
                              }
                              // Update BLoC state
                              context.read<BudgetingBloc>().add(
                                BudgetingUpdateExpenseCategoryPercentage(
                                  categoryId: categoryId,
                                  percentage: clampedValue,
                                ),
                              );
                            },
                          ),
                        if (suggestion.lowerBound != null &&
                            suggestion.upperBound != null &&
                            isSelected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 16),
                            child: Text(
                              'Saran: ${suggestion.lowerBound?.toStringAsFixed(0)}% - ${suggestion.upperBound?.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

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
                        '${totalAllocatedPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: (totalAllocatedPercentage > 100)
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.smallPadding),
              const Text(
                AppStrings.calculationNote,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              const SizedBox(height: AppDimensions.padding),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: state.loading
                    ? null
                    : () {
                        // Client-side validation before navigating
                        if (state.selectedExpenseCategoryIds.isEmpty &&
                            totalAllocatedPercentage > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Pilih minimal 1 kategori untuk dialokasikan.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (totalAllocatedPercentage > 0 &&
                            (totalAllocatedPercentage < 99.99 ||
                                totalAllocatedPercentage > 100.01)) {
                          // Allow for float precision
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Total alokasi persentase harus mencapai 100% atau 0%.',
                              ),
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
                ), // "Lanjut ke Subkategori"
              ),
            ],
          ),
        );
      },
    );
  }
}

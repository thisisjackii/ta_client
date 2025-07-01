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
import 'package:ta_client/features/budgeting/view/widgets/budgeting_criteria.dart';
import 'package:ta_client/features/budgeting/view/widgets/budgeting_flow_navigation_guard.dart';
import 'package:ta_client/features/profile/bloc/profile_bloc.dart';
import 'package:ta_client/features/profile/bloc/profile_state.dart'
    as ProfileBlocState;

class BudgetingAllocationPage extends StatefulWidget {
  const BudgetingAllocationPage({super.key});

  @override
  _BudgetingAllocationPageState createState() =>
      _BudgetingAllocationPageState();
}

class _BudgetingAllocationPageState extends State<BudgetingAllocationPage>
    with BudgetingFlowNavigationGuard {
  final Map<String, TextEditingController> _percentageControllers = {};
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  _snackBarController;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<BudgetingBloc>();
    // Ensure suggestions are loaded if not already, especially if coming from date selection
    if (bloc.state.expenseCategorySuggestions.isEmpty &&
        !bloc.state.loading &&
        bloc.state.planDateConfirmed) {
      bloc.add(const BudgetingLoadExpenseSuggestionsAndExistingPlan());
    }
    _updateControllersFromBlocState(bloc.state);
  }

  void _updateControllersFromBlocState(BudgetingState blocState) {
    blocState.expenseAllocationPercentages.forEach((categoryId, value) {
      if (_percentageControllers[categoryId] == null) {
        _percentageControllers[categoryId] = TextEditingController();
      }
      if (_percentageControllers[categoryId]!.text !=
          value.toStringAsFixed(0)) {
        _percentageControllers[categoryId]!.text = value.toStringAsFixed(0);
        _percentageControllers[categoryId]!
            .selection = TextSelection.fromPosition(
          TextPosition(offset: _percentageControllers[categoryId]!.text.length),
        );
      }
    });
    // Remove controllers for categories no longer in BLoC state (e.g., if deselected)
    final blocCategoryIds = blocState.expenseAllocationPercentages.keys.toSet();
    _percentageControllers.removeWhere(
      (key, value) => !blocCategoryIds.contains(key),
    );
  }

  @override
  void dispose() {
    _percentageControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<ProfileBloc>().state;
    late final OccupationGroup occupationGroup;
    if (profileState is ProfileBlocState.ProfileLoadSuccess) {
      occupationGroup = getOccupationGroup(profileState.user.occupationName);
    } else {
      occupationGroup =
          OccupationGroup.pekerja; // Default if profile not loaded
    }
    return PopScope(
      // <<< REPLACED WillPopScope
      canPop: canPopBudgetingFlow(context), // <<< USE MIXIN METHOD
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        // <<< UPDATED SIGNATURE
        if (didPop) return;
        await handlePopAttempt(
          context: context,
          didPop: didPop,
          result: result,
        ); // <<< USE MIXIN METHOD
      },
      child: BlocConsumer<BudgetingBloc, BudgetingState>(
        listenWhen: (prev, curr) =>
            curr.error != null ||
            curr.infoMessage != null ||
            prev.expenseAllocationPercentages !=
                curr.expenseAllocationPercentages ||
            prev.selectedExpenseCategoryIds != curr.selectedExpenseCategoryIds,
        listener: (context, state) {
          if (state.error != null) {
            _snackBarController?.close();
            _snackBarController = ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
            context.read<BudgetingBloc>().add(BudgetingClearError());
          }
          if (state.infoMessage != null) {
            _snackBarController?.close();
            _snackBarController = ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.infoMessage!)));
            context.read<BudgetingBloc>().add(BudgetingClearInfoMessage());
          }
          _updateControllersFromBlocState(state);
        },
        buildWhen: (prev, curr) =>
            prev.loading != curr.loading ||
            prev.expenseCategorySuggestions !=
                curr.expenseCategorySuggestions ||
            prev.selectedExpenseCategoryIds !=
                curr.selectedExpenseCategoryIds ||
            prev.expenseAllocationPercentages !=
                curr.expenseAllocationPercentages ||
            prev.isEditing != curr.isEditing || // Listen for edit mode changes
            prev.initialSpendingForEditedPlan !=
                curr.initialSpendingForEditedPlan,
        builder: (context, state) {
          if (state.loading &&
              state.expenseCategorySuggestions.isEmpty &&
              !state.isEditing) {
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
                onPressed: () =>
                    handleAppBarOrButtonCancel(context), // <<< USE MIXIN METHOD
              ),
              automaticallyImplyLeading: false,
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

                  _percentageControllers.putIfAbsent(
                    categoryId,
                    () => TextEditingController(
                      text: currentPercentage.toStringAsFixed(0),
                    ),
                  );

                  final sumOfOtherSelectedPercentages = state
                      .selectedExpenseCategoryIds
                      .where((id) => id != categoryId)
                      .fold(
                        0.toDouble(),
                        (sum, id) =>
                            sum +
                            (state.expenseAllocationPercentages[id] ?? 0.0),
                      );
                  final maxPercentageForThisCategory =
                      (100.0 - sumOfOtherSelectedPercentages).clamp(0.0, 100.0);
                  final hasSpendingForThisCategory =
                      state.isEditing &&
                      (state.initialSpendingForEditedPlan[categoryId] ?? 0.0) >
                          0;

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
                                onChanged: hasSpendingForThisCategory
                                    ? null
                                    : (selected) {
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
                                width: 70,
                                child: TextFormField(
                                  controller:
                                      _percentageControllers[categoryId],
                                  enabled:
                                      isSelected && !hasSpendingForThisCategory,
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
                                    if (isSelected &&
                                        !hasSpendingForThisCategory) {
                                      final p =
                                          (double.tryParse(valueStr) ?? 0.0)
                                              .clamp(
                                                0.0,
                                                maxPercentageForThisCategory,
                                              );
                                      context.read<BudgetingBloc>().add(
                                        BudgetingUpdateExpenseCategoryPercentage(
                                          categoryId: categoryId,
                                          percentage: p,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (isSelected)
                            FlutterSlider(
                              values: [currentPercentage.clamp(0.0, 100.0)],
                              min: 0,
                              max: 100,
                              disabled:
                                  !isSelected || hasSpendingForThisCategory,
                              onDragging: (handlerIndex, lowerValue, upperValue) {
                                if (hasSpendingForThisCategory) return;
                                final attemptedValue = (lowerValue as num)
                                    .toDouble();
                                final clampedValue = attemptedValue.clamp(
                                  0.0,
                                  maxPercentageForThisCategory,
                                );
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
                                // final kapoorRange =
                                //     kapoorMinMax[occupationGroup]?[categoryName];
                                // if (kapoorRange != null &&
                                //     (clampedValue < kapoorRange[0] ||
                                //         clampedValue > kapoorRange[1])) {
                                //   if (_snackBarController == null) {
                                //     _snackBarController =
                                //         ScaffoldMessenger.of(
                                //           context,
                                //         ).showSnackBar(
                                //           SnackBar(
                                //             content: Text(
                                //               'Saran alokasi untuk "$categoryName": ${kapoorRange[0]}% - ${kapoorRange[1]}%',
                                //             ),
                                //             backgroundColor:
                                //                 Colors.orangeAccent,
                                //           ),
                                //         );
                                //     _snackBarController!.closed.then(
                                //       (_) => _snackBarController = null,
                                //     );
                                //   }
                                // }
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
                  onPressed:
                      state.loading ||
                          (state.isEditing &&
                              state.initialSpendingForEditedPlan.values.any(
                                (s) => s > 0,
                              ) &&
                              state.selectedExpenseCategoryIds.any(
                                (id) =>
                                    (state.initialSpendingForEditedPlan[id] ??
                                        0.0) >
                                    0,
                              ))
                      ? null
                      : () {
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Total alokasi persentase harus mencapai 100%.',
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
                    'Lanjut ke Subkategori',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

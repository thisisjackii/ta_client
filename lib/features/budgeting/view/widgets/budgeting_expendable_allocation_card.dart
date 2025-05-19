// lib/features/budgeting/view/widgets/budgeting_expendable_allocation_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
// For SelectIncomeSubcategory
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
// For typing

class BudgetingExpandableAllocationCard extends StatelessWidget {
  const BudgetingExpandableAllocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      // Rebuild only if these relevant parts of the state change
      buildWhen: (prev, curr) =>
          prev.incomeSummary != curr.incomeSummary ||
          prev.selectedIncomeSubcategoryIds !=
              curr.selectedIncomeSubcategoryIds,
      builder: (context, state) {
        // Calculate total selected income based on the new state structure
        double totalSelectedIncome = 0;
        final selectedIncomeWidgets = <Widget>[];

        if (state.incomeSummary.isNotEmpty) {
          for (final categorySummary
              in state.incomeSummary) {
            var parentCategoryHasSelectedSub = false;
            final subcategoryTiles = <Widget>[];

            for (final subIncome
                in categorySummary.subcategories) {
              if (state.selectedIncomeSubcategoryIds.contains(
                subIncome.subcategoryId,
              )) {
                totalSelectedIncome += subIncome.totalAmount;
                parentCategoryHasSelectedSub = true;
                subcategoryTiles.add(
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                    ), // Indent subcategories
                    child: CheckboxListTile(
                      value: true, // Always true if it's in the selected list
                      enabled:
                          false, // Display only, selection happens on BudgetingIncomePage
                      title: Text(
                        subIncome.subcategoryName,
                        style: const TextStyle(fontSize: 13),
                      ),
                      secondary: Text(
                        formatToRupiah(subIncome.totalAmount),
                        style: const TextStyle(fontSize: 13),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      onChanged: null, // Not interactive here
                    ),
                  ),
                );
              }
            }
            // If any subcategory under this parent was selected, add the parent category header
            if (parentCategoryHasSelectedSub) {
              selectedIncomeWidgets.add(
                ListTile(
                  dense: true,
                  title: Text(
                    categorySummary.categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  // Optionally display category total if needed, though subcategories show individual amounts
                  // trailing: Text(formatToRupiah(categorySummary.categoryTotalAmount), style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
              selectedIncomeWidgets.addAll(subcategoryTiles);
              selectedIncomeWidgets.add(
                const SizedBox(height: 4),
              ); // Spacer after a category group
            }
          }
        }

        if (selectedIncomeWidgets.isEmpty && state.incomeSummary.isNotEmpty) {
          selectedIncomeWidgets.add(
            const ListTile(
              dense: true,
              title: Center(
                child: Text(
                  'Tidak ada sumber pemasukan yang dipilih.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ),
            ),
          );
        } else if (state.incomeSummary.isEmpty &&
            state.incomeDateConfirmed &&
            !state.loading) {
          selectedIncomeWidgets.add(
            const ListTile(
              dense: true,
              title: Center(
                child: Text(
                  'Tidak ada data pemasukan untuk periode ini.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.smallPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          elevation: 2,
          child: ExpansionTile(
            key: const PageStorageKey<String>(
              'incomeAllocationSummary',
            ), // Unique key
            maintainState: true, // Keep state when collapsed/expanded
            initiallyExpanded: true, // Start expanded
            tilePadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.padding,
              vertical: AppDimensions.smallPadding / 2,
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.smallPadding),
                const Text(
                  AppStrings
                      .expendableAllocationCardTitle, // "Alokasi Dana Pemasukan"
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  formatToRupiah(totalSelectedIncome),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            children:
                selectedIncomeWidgets.isEmpty &&
                    !state.loading &&
                    state.incomeDateConfirmed
                ? [
                    const ListTile(
                      title: Center(
                        child: Text(
                          'Pilih sumber pemasukan pada langkah sebelumnya.',
                        ),
                      ),
                    ),
                  ]
                : selectedIncomeWidgets,
            // No "Save" button here as income selection is done on a previous page (BudgetingIncomePage)
          ),
        );
      },
    );
  }
}

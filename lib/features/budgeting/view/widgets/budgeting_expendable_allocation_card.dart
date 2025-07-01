// lib/features/budgeting/view/widgets/budgeting_expendable_allocation_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/app_strings.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingExpandableAllocationCard extends StatelessWidget {
  const BudgetingExpandableAllocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      buildWhen: (prev, curr) =>
          prev.incomeSummary != curr.incomeSummary ||
          prev.selectedIncomeSubcategoryIds !=
              curr.selectedIncomeSubcategoryIds ||
          prev.currentBudgetPlan?.totalCalculatedIncome !=
              curr.currentBudgetPlan?.totalCalculatedIncome ||
          prev.totalCalculatedIncome !=
              curr.totalCalculatedIncome || // For creation flow
          prev.loading != curr.loading,
      builder: (context, state) {
        double displayTotalIncome = 0;
        final incomeBreakdownWidgets = <Widget>[];

        // Determine the total income to display in the header
        if (state.currentBudgetPlan != null) {
          displayTotalIncome = state.currentBudgetPlan!.totalCalculatedIncome;
        } else {
          // In creation flow, use the interactively calculated total
          displayTotalIncome = state.totalCalculatedIncome;
        }

        // Build the breakdown list if incomeSummary is available and selectedIncomeSubcategoryIds are set
        // (which they will be if a plan is loaded and incomeSummary is fetched for its period)
        if (state.incomeSummary.isNotEmpty &&
            state.selectedIncomeSubcategoryIds.isNotEmpty) {
          for (final categorySummary in state.incomeSummary) {
            var parentCategoryHasSelectedSub = false;
            final subcategoryTiles = <Widget>[];

            for (final subIncome in categorySummary.subcategories) {
              // Check if this subcategory ID is in the BLoC's selected list
              if (state.selectedIncomeSubcategoryIds.contains(
                subIncome.subcategoryId,
              )) {
                parentCategoryHasSelectedSub = true;
                subcategoryTiles.add(
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 8,
                    ), // Added right padding
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      leading: Icon(
                        Icons
                            .check_box, // Show as checked because it's "selected" for display
                        color: Colors
                            .grey[400], // Greyed out to indicate display-only
                        size: 18,
                      ),
                      title: Text(
                        subIncome.subcategoryName,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Text(
                        formatToRupiah(subIncome.totalAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              }
            }
            if (parentCategoryHasSelectedSub) {
              incomeBreakdownWidgets.add(
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  title: Text(
                    categorySummary.categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
              incomeBreakdownWidgets.addAll(subcategoryTiles);
              incomeBreakdownWidgets.add(const SizedBox(height: 4));
            }
          }
        }

        // Determine what to show in the expansion tile's children
        List<Widget> childrenToShow;
        if (state.loading && state.incomeSummary.isEmpty) {
          // If loading initial income summary
          childrenToShow = [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ];
        } else if (incomeBreakdownWidgets.isNotEmpty) {
          childrenToShow = incomeBreakdownWidgets;
        } else if (state.incomeDateConfirmed &&
            !state.loading &&
            displayTotalIncome == 0) {
          childrenToShow = [
            const ListTile(
              title: Center(
                child: Text(
                  'Tidak ada data pemasukan untuk periode ini.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ),
            ),
          ];
        } else if (state.incomeDateConfirmed &&
            !state.loading &&
            displayTotalIncome > 0) {
          // Has total income from plan, but breakdown couldn't be formed (e.g. incomeSummary fetch failed or empty)
          childrenToShow = [
            ListTile(
              title: Center(
                child: Text(
                  'Rincian sumber pemasukan tidak tersedia (Total: ${formatToRupiah(displayTotalIncome)}).',
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ];
        } else {
          childrenToShow = [
            const ListTile(
              title: Center(
                child: Text(
                  'Pilih periode pemasukan untuk melihat rincian.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                ),
              ),
            ),
          ];
        }

        return Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.smallPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
          elevation: 2,
          child: ExpansionTile(
            key: const PageStorageKey<String>('incomeAllocationSummary'),
            maintainState: true,
            initiallyExpanded:
                displayTotalIncome > 0 || incomeBreakdownWidgets.isNotEmpty,
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
                  AppStrings.expendableAllocationCardTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                Text(
                  formatToRupiah(displayTotalIncome),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            children: childrenToShow,
          ),
        );
      },
    );
  }
}

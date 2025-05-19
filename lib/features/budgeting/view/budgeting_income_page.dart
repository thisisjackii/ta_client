// lib/features/budgeting/view/budgeting_income_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
// Import the actual model for income summary

class BudgetingIncomePage extends StatelessWidget {
  // Can be StatelessWidget if not managing local state
  const BudgetingIncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      // buildWhen: (prev, curr) => prev.loading != curr.loading || prev.incomeSummary != curr.incomeSummary || prev.error != curr.error,
      builder: (ctx, state) {
        final dateFormat = DateFormat('dd/MM/yyyy');
        final rangeText =
            (state.incomeStartDate != null && state.incomeEndDate != null)
            ? '${dateFormat.format(state.incomeStartDate!)} - ${dateFormat.format(state.incomeEndDate!)}'
            : 'Periode pemasukan belum diatur';

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Pilih Sumber Dana Pemasukan',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.greyBackground,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Go back to income date selection or intro based on flow
                Navigator.pushReplacementNamed(
                  context,
                  Routes.budgetingIncomeDate,
                );
              },
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text(
                    'Periode: $rangeText',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (state.loading && state.incomeSummary.isEmpty)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.error != null && state.incomeSummary.isEmpty)
                  Expanded(child: Center(child: Text('Error: ${state.error}')))
                else if (!state.incomeDateConfirmed)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Silakan konfirmasi periode pemasukan terlebih dahulu.',
                      ),
                    ),
                  )
                else if (state.incomeSummary.isEmpty && !state.loading)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Tidak ada data pemasukan untuk periode ini.',
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      children: [
                        // state.incomeSummary is List<BackendIncomeSummaryItem>
                        ...state.incomeSummary.expand((categorySummary) {
                          return [
                            if (categorySummary
                                .subcategories
                                .isNotEmpty) // Only show category header if it has subcategories
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 4,
                                ),
                                child: Text(
                                  categorySummary.categoryName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ...categorySummary.subcategories.map((
                              subcatSummary,
                            ) {
                              return CheckboxListTile(
                                value: state.selectedIncomeSubcategoryIds
                                    .contains(subcatSummary.subcategoryId),
                                title: Text(subcatSummary.subcategoryName),
                                subtitle: Text(
                                  formatToRupiah(subcatSummary.totalAmount),
                                ),
                                onChanged: (_) => ctx.read<BudgetingBloc>().add(
                                  BudgetingSelectIncomeSubcategory(
                                    subcategoryId: subcatSummary.subcategoryId,
                                  ),
                                ),
                              );
                            }),
                          ];
                        }),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed:
                              state.selectedIncomeSubcategoryIds.isEmpty &&
                                  state.incomeSummary.isNotEmpty
                              ? null // Disable if incomes available but none selected
                              : () => Navigator.pushNamed(
                                  context,
                                  Routes.budgetingAllocationDate,
                                ),
                          child: const Text('Lanjut ke Alokasi Pengeluaran'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

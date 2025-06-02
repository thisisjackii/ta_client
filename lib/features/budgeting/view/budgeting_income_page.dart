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
import 'package:ta_client/features/budgeting/view/widgets/budgeting_flow_navigation_guard.dart';

class BudgetingIncomePage extends StatefulWidget {
  const BudgetingIncomePage({super.key});

  @override
  State<BudgetingIncomePage> createState() => _BudgetingIncomePageState();
}

class _BudgetingIncomePageState extends State<BudgetingIncomePage>
    with BudgetingFlowNavigationGuard {
  @override
  Widget build(BuildContext context) {
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
      child: BlocBuilder<BudgetingBloc, BudgetingState>(
        builder: (ctx, state) {
          final dateFormat = DateFormat('dd/MM/yyyy');
          final rangeText =
              (state.incomeCalculationStartDate != null &&
                  state.incomeCalculationEndDate != null)
              ? '${dateFormat.format(state.incomeCalculationStartDate!)} - ${dateFormat.format(state.incomeCalculationEndDate!)}'
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
                onPressed: () =>
                    handleAppBarOrButtonCancel(context), // <<< USE MIXIN METHOD
              ),
              automaticallyImplyLeading: false,
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
                    Expanded(
                      child: Center(child: Text('Error: ${state.error}')),
                    )
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
                          ...state.incomeSummary.expand((categorySummary) {
                            return [
                              if (categorySummary.subcategories.isNotEmpty)
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
                                  onChanged: (_) =>
                                      ctx.read<BudgetingBloc>().add(
                                        BudgetingSelectIncomeSubcategory(
                                          subcategoryId:
                                              subcatSummary.subcategoryId,
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
                                ? null
                                : () {
                                    context.read<BudgetingBloc>().add(
                                      BudgetingTotalIncomeConfirmed(
                                        state.totalCalculatedIncome,
                                      ),
                                    );
                                    Navigator.pushNamed(
                                      context,
                                      Routes.budgetingAllocationDate,
                                    );
                                  },
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
      ),
    );
  }
}

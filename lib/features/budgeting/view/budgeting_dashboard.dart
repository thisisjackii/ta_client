// lib/features/budgeting/view/budgeting_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/core/constants/category_mapping.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/view/widgets/budgeting_expendable_allocation_card.dart';

class BudgetingDashboard extends StatefulWidget {
  const BudgetingDashboard({super.key});

  @override
  State<BudgetingDashboard> createState() => _BudgetingDashboardState();
}

class _BudgetingDashboardState extends State<BudgetingDashboard>
    with RouteAware {
  final Set<String> _warned90 = {};
  final Set<String> _warned100 = {};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Alokasi Keuanganmu'),
            backgroundColor: AppColors.primary,
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppDimensions.padding),
            children: [
              const BudgetingExpandableAllocationCard(),
              Center(
                child: Card(
                  color: AppColors.dateCardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.padding,
                      vertical: AppDimensions.smallPadding,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.date_range,
                          size: AppDimensions.iconSize,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: AppDimensions.smallPadding),
                        Text(
                          '${state.startDate != null ? DateFormat('dd/MM/yyyy').format(state.startDate!) : '--'}'
                          ' - '
                          '${state.endDate != null ? DateFormat('dd/MM/yyyy').format(state.endDate!) : '--'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.smallPadding),

              // --- Allocation cards + progress bars ---
              ...state.allocations
                  .where((a) => state.selectedCategories.contains(a.title))
                  .map((alloc) {
                final current =
                    state.allocationValues[alloc.id]! / 100 * alloc.target;
                final ratio = alloc.target == 0 ? 0.0 : current / alloc.target;
                final percent = ratio * 100;
                final Color barColor = percent <= 32
                    ? Colors.green
                    : percent <= 65
                        ? Colors.orange
                        : Colors.red;
                final inputsEnabled = percent <= 0;
                final subs = categoryMapping[alloc.title] ?? [];

                // 90% warning
                if (percent >= 90 &&
                    percent < 100 &&
                    !_warned90.contains(alloc.title)) {
                  _warned90.add(alloc.title);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '⚠️ Anggaran "${alloc.title}" sudah mencapai 90%. '
                          'Kelola pengeluaran dengan bijak!',
                        ),
                        backgroundColor: Colors.orange[700],
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  });
                }

                // 100% alert
                if (percent >= 100 && !_warned100.contains(alloc.title)) {
                  _warned100.add(alloc.title);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Batas Maksimum Terpenuhi'),
                        content: Text(
                          'Perhatian! Anggaran untuk kategori "${alloc.title}" telah mencapai atau melebihi 100%.\n'
                          'Anda telah mencapai batas maksimum yang ditetapkan!',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  });
                }

                return Card(
                  margin:
                      const EdgeInsets.only(bottom: AppDimensions.smallPadding),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadius),
                  ),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        const Icon(Icons.category),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(alloc.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,),),),
                        Text(
                            '${formatToRupiah(current)} / ${formatToRupiah(alloc.target)}',),
                      ],
                    ),
                    subtitle: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      backgroundColor: AppColors.greyBackground,
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                    children: [
                      ...subs.map((sub) {
                        final checked = state.selectedSubExpenses[alloc.title]
                                ?.contains(sub) ??
                            false;
                        return CheckboxListTile(
                          title: Text(sub),
                          value: checked,
                          onChanged: inputsEnabled
                              ? (val) => context.read<BudgetingBloc>().add(
                                    ToggleExpenseSubItem(
                                      allocationId: alloc.title,
                                      subItem: sub,
                                      isSelected: val!,
                                    ),
                                  )
                              : null,
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8,),
                        child: ElevatedButton(
                          onPressed: inputsEnabled
                              ? () {
                                  // you can dispatch a SaveExpenseAllocation event
                                }
                              : null,
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

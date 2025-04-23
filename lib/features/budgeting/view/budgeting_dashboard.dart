// lib/features/budgeting/view/budgeting_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/core/constants/app_colors.dart';
import 'package:ta_client/core/constants/app_dimensions.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';
import 'package:ta_client/features/budgeting/view/widgets/budgeting_expendable_allocation_card.dart';

class BudgetingDashboard extends StatelessWidget {
  const BudgetingDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
        builder: (context, state) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Alokasi Keuanganmu'),
            backgroundColor: AppColors.primary,),
        body: ListView(
          padding: const EdgeInsets.all(AppDimensions.padding),
          children: [
            const BudgetingExpandableAllocationCard(),
            Center(
              child: Card(
                color: AppColors.dateCardBackground,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadius),),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.padding,
                      vertical: AppDimensions.smallPadding,),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.date_range,
                          size: AppDimensions.iconSize, color: Colors.grey,),
                      const SizedBox(width: AppDimensions.smallPadding),
                      Text(
                        '${state.startDate != null ? DateFormat('dd/MM/yyyy').format(state.startDate!) : '--'} - ${state.endDate != null ? DateFormat('dd/MM/yyyy').format(state.endDate!) : '--'}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500,),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.smallPadding),
            ...state.allocations.map((alloc) {
              final current =
                  state.allocationValues[alloc.id]! / 100 * alloc.target;
              final ratio = alloc.target == 0 ? 0.0 : current / alloc.target;
              final percent = ratio * 100;
              final Color color = percent <= 32
                  ? Colors.green
                  : percent <= 65
                      ? Colors.orange
                      : Colors.red;
              return Card(
                margin:
                    const EdgeInsets.only(bottom: AppDimensions.smallPadding),
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimensions.cardRadius),),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.smallPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category),
                          const SizedBox(width: AppDimensions.smallPadding),
                          Expanded(
                              child: Text(alloc.title,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,),),),
                          Text(
                              '${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0).format(current)} / ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0).format(alloc.target)}',),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.smallPadding),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          LinearProgressIndicator(
                            value: ratio,
                            minHeight: 18,
                            backgroundColor: AppColors.greyBackground,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                          Text('${percent.toStringAsFixed(1)}%'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    },);
  }
}

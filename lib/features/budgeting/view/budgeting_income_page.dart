// lib/features/budgeting/view/budgeting_income_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/utils/calculations.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_event.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_state.dart';

class BudgetingIncomePage extends StatefulWidget {
  const BudgetingIncomePage({super.key});

  @override
  _BudgetingIncomePageState createState() => _BudgetingIncomePageState();
}

class _BudgetingIncomePageState extends State<BudgetingIncomePage>
    with RouteAware {
  final _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    // wait for user to pick a date range before fetching data
  }

  Future<void> _pickDateRange() async {
    final bloc = context.read<BudgetingBloc>();
    final state = bloc.state;

    final initialStart = state.startDate ?? DateTime.now();
    final initialEnd = state.endDate ?? DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );

    if (picked != null) {
      // dispatch and auto-load data for the chosen range
      bloc.add(ConfirmDateRange(start: picked.start, end: picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetingBloc, BudgetingState>(
      builder: (ctx, state) {
        final rangeText = (state.startDate != null && state.endDate != null)
            ? '${_dateFormat.format(state.startDate!)} - ${_dateFormat.format(state.endDate!)}'
            : 'Pilih rentang tanggal';

        return Scaffold(
          appBar: AppBar(title: const Text('Pilih Sumber Dana')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: InkWell(
                    onTap: _pickDateRange,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(rangeText),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (state.loading)
                  const Center(child: CircularProgressIndicator()),
                if (state.error != null)
                  Center(child: Text('Error: ${state.error}')),

                // show incomes only after user-selected date range has been confirmed
                if (!state.loading && state.dateConfirmed)
                  Expanded(
                    child: ListView(
                      children: [
                        for (final inc in state.incomes)
                          CheckboxListTile(
                            value: state.selectedIncomeIds.contains(inc.id),
                            title: Text(
                              '${inc.title} — ${formatToRupiah(inc.value.toDouble())}',
                            ),
                            onChanged: (_) => ctx
                                .read<BudgetingBloc>()
                                .add(SelectIncomeCategory(inc.id)),
                          ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: state.selectedIncomeIds.isEmpty
                              ? null
                              : () => Navigator.pushNamed(
                                    context,
                                    Routes.budgetingAllocationPage,
                                  ),
                          child: const Text('Lanjut ke Alokasi'),
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

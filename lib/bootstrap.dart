import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/transaction/services/transaction_sync_service.dart';

Future<void> _openAllHiveBoxes() async {
  await Hive.openBox<String>('secureBox');
  await Hive.openBox<String>(
    'transactionBox',
  ); // Assuming this stores JSON strings of transactions
  await Hive.openBox<String>(
    'transactionHierarchyBox',
  ); // If TransactionHierarchyRepository uses this

  // Budgeting boxes (from BudgetingRepository._initHiveBoxes)
  await Hive.openBox<String>('budgetingIncomeSummaryCache_v1');
  await Hive.openBox<String>('budgetingExpenseSuggestionsCache_v1');
  await Hive.openBox<String>('budgetingSavedAllocationsCache_v1');
  await Hive.openBox<String>('budgetingPendingPlans_v1');

  // Period box (from PeriodRepository._initHiveBoxes - ensure consistency)
  await Hive.openBox<String>('periodsCacheBox'); // Example name
  await Hive.openBox<String>('pendingPeriodsCacheBox'); // Example name

  await Hive.openBox<String>('budgetingIncomeSummaryCache_v1'); // etc.
  await Hive.openBox<String>('budgetingExpenseSuggestionsCache_v1');
  await Hive.openBox<String>('budgetingSavedAllocationsCache_v1');
  await Hive.openBox<String>('budgetingPendingPlans_v1');

  await Hive.openBox<String>('pendingTransactionsQueue_v2'); // Example name
  await Hive.openBox<String>('transactionListCache_v2'); // Example name

  debugPrint('All Hive boxes opened globally.');
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await Hive.initFlutter();
  await _openAllHiveBoxes();
  // Add cross-flavor configuration here
  setupServiceLocator();
  // Attempt auto-login *after* GetIt is set up and Hive is ready
  // This is important because AuthState constructor now calls tryAutoLogin which uses sl<HiveService>()
  if (sl.isRegistered<AuthState>()) {
    await sl<AuthState>()
        .tryAutoLogin(); // Await this to ensure state is set before initial build
  }
  if (sl.isRegistered<TransactionSyncService>()) {
    sl<TransactionSyncService>().startListening();
  } else {
    debugPrint('Warning: TransactionSyncService not registered in GetIt.');
  }

  runApp(await builder());
}

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

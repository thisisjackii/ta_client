// lib/core/services/service_locator.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';
import 'package:ta_client/features/transaction/services/transaction_sync_service.dart';

final sl = GetIt.instance;
final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000/api/v1';

void setupServiceLocator() {
  sl
    ..registerLazySingleton<AuthState>(AuthState.new)
    ..registerLazySingleton<TransactionService>(
      () => TransactionService(
        baseUrl: baseUrl,
      ), // https://ta-server-f649ec90e07a.herokuapp.com/api/v1
    )
    ..registerLazySingleton<ConnectivityService>(ConnectivityService.new)
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepository(transactionService: sl<TransactionService>()),
    )
    ..registerLazySingleton<TransactionSyncService>(
      () => TransactionSyncService(repository: sl<TransactionRepository>()),
    )
    ..registerLazySingleton<BudgetingService>(
      () => BudgetingService(baseUrl: baseUrl),
    )
    ..registerLazySingleton<BudgetingRepository>(
      () => BudgetingRepository(sl<BudgetingService>()),
    )
    ..registerLazySingleton<EvaluationService>(
      () => EvaluationService(transactionService: sl<TransactionService>()),
    )
    ..registerLazySingleton<EvaluationRepository>(
      () => EvaluationRepository(sl<EvaluationService>()),
    );
}

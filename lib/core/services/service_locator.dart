// lib/core/services/service_locator.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/budgeting/repositories/period_repository.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';
import 'package:ta_client/features/budgeting/services/period_service.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart';
import 'package:ta_client/features/login/services/login_service.dart';
import 'package:ta_client/features/otp/services/otp_service.dart';
import 'package:ta_client/features/profile/repositories/profile_repository.dart';
import 'package:ta_client/features/profile/services/profile_service.dart';
import 'package:ta_client/features/register/services/register_service.dart';
import 'package:ta_client/features/transaction/repositories/transaction_hierarchy_repository.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_hierarchy_service.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';
import 'package:ta_client/features/transaction/services/transaction_sync_service.dart';

final sl = GetIt.instance;
final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000/api/v1';

void setupServiceLocator() {
  sl
    ..registerLazySingleton<ConnectivityService>(() => ConnectivityService())
    ..registerLazySingleton<AuthState>(
      () => AuthState(),
    ) // Global simple auth state
    // --- Authentication & User Feature ---
    ..registerLazySingleton<RegisterService>(
      () => RegisterService(baseUrl: baseUrl),
    )
    ..registerLazySingleton<LoginService>(() => LoginService(baseUrl: baseUrl))
    ..registerLazySingleton<OtpService>(() => OtpService(baseUrl: baseUrl))
    ..registerLazySingleton<ProfileService>(
      () => ProfileService(baseUrl: baseUrl),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepository(service: sl<ProfileService>()),
    )
    // --- Transaction Feature ---
    // Note: TransactionService now depends on AuthenticatedClient, which reads from Hive.
    // Make sure Hive is initialized before services that use AuthenticatedClient are first accessed.
    ..registerLazySingleton<TransactionService>(
      () => TransactionService(baseUrl: baseUrl),
    )
    ..registerLazySingleton<TransactionHierarchyService>(
      () => TransactionHierarchyService(baseUrl: baseUrl),
    ) // Assuming it's public or uses different auth
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepository(transactionService: sl<TransactionService>()),
    )
    ..registerLazySingleton<TransactionHierarchyRepository>(
      () => TransactionHierarchyRepository(
        service: sl<TransactionHierarchyService>(),
      ),
    )
    // --- Period Feature (for Budgeting & Evaluation context) ---
    ..registerLazySingleton<PeriodService>(
      () => PeriodService(baseUrl: baseUrl),
    )
    ..registerLazySingleton<PeriodRepository>(
      () => PeriodRepository(sl<PeriodService>()),
    )
    // --- Budgeting Feature ---
    ..registerLazySingleton<BudgetingService>(
      () => BudgetingService(
        baseUrl: baseUrl,
      ), // Doesn't need TransactionService directly anymore
    )
    ..registerLazySingleton<BudgetingRepository>(
      () => BudgetingRepository(
        sl<BudgetingService>(),
        sl<
          TransactionRepository
        >(), // For offline income calculation from cached transactions
        sl<PeriodRepository>(), // Injected as the third required argument
      ),
    )
    // --- Evaluation Feature ---
    ..registerLazySingleton<EvaluationService>(
      () => EvaluationService(baseUrl: baseUrl),
    )
    ..registerLazySingleton<EvaluationRepository>(
      () => EvaluationRepository(
        sl<EvaluationService>(),
        sl<
          TransactionRepository
        >(), // For offline calculation from cached transactions
        // sl<PeriodRepository>(), // If needed for period context in offline evaluation
      ),
    )
    // --- Transaction Sync Service ---
    // This needs all repositories that have pending data to sync
    ..registerLazySingleton<TransactionSyncService>(
      () => TransactionSyncService(
        transactionRepository: sl<TransactionRepository>(),
        budgetingRepository: sl<BudgetingRepository>(),
        periodRepository: sl<PeriodRepository>(),
      ),
    );
}

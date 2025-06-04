// lib/core/services/service_locator.dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/first_launch_service.dart';
import 'package:ta_client/core/services/hive_service.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/core/utils/dio_client.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/budgeting/services/budgeting_service.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';
import 'package:ta_client/features/evaluation/services/evaluation_service.dart';
import 'package:ta_client/features/login/services/login_service.dart';
import 'package:ta_client/features/profile/repositories/profile_repository.dart';
import 'package:ta_client/features/profile/services/profile_service.dart';
import 'package:ta_client/features/register/bloc/register_bloc.dart';
import 'package:ta_client/features/register/services/register_service.dart';
import 'package:ta_client/features/transaction/repositories/transaction_hierarchy_repository.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_hierarchy_service.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';
import 'package:ta_client/features/transaction/services/transaction_sync_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // Register Dio instance first
  sl
    // --- Core Services ---
    ..registerLazySingleton<Dio>(createDioInstance)
    ..registerLazySingleton<HiveService>(HiveService.new)
    ..registerLazySingleton<ConnectivityService>(ConnectivityService.new)
    ..registerLazySingleton<AuthState>(AuthState.new)
    ..registerLazySingleton<FirstLaunchService>(FirstLaunchService.new)
    // --- Authentication & User Feature ---
    // Services now take Dio instance instead of baseUrl
    ..registerLazySingleton<RegisterService>(
      () => RegisterService(dio: sl<Dio>()),
    )
    ..registerLazySingleton<LoginService>(() => LoginService(dio: sl<Dio>()))
    ..registerLazySingleton<ProfileService>(
      () => ProfileService(dio: sl<Dio>()),
    )
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepository(service: sl<ProfileService>()),
    )
    // --- Transaction Feature ---
    ..registerLazySingleton<TransactionService>(
      () => TransactionService(dio: sl<Dio>()),
    )
    ..registerLazySingleton<TransactionHierarchyService>(
      () => TransactionHierarchyService(dio: sl<Dio>()),
    )
    ..registerLazySingleton<TransactionRepository>(
      () => TransactionRepository(transactionService: sl<TransactionService>()),
    )
    ..registerLazySingleton<TransactionHierarchyRepository>(
      () => TransactionHierarchyRepository(
        service: sl<TransactionHierarchyService>(),
      ),
    )
    // --- Budgeting Feature ---
    ..registerLazySingleton<BudgetingService>(
      () => BudgetingService(dio: sl<Dio>()),
    )
    ..registerLazySingleton<BudgetingRepository>(
      () => BudgetingRepository(
        sl<BudgetingService>(),
        sl<TransactionRepository>(),
      ),
    )
    // --- Evaluation Feature ---
    ..registerLazySingleton<EvaluationService>(
      () => EvaluationService(
        dio: sl<Dio>(), // Pass Dio
        // transactionService: sl<TransactionService>(),
      ),
    )
    ..registerLazySingleton<EvaluationRepository>(
      () => EvaluationRepository(
        sl<EvaluationService>(),
        sl<TransactionRepository>(),
      ),
    )
    // --- Transaction Sync Service ---
    ..registerLazySingleton<TransactionSyncService>(
      () => TransactionSyncService(
        transactionRepository: sl<TransactionRepository>(),
        budgetingRepository: sl<BudgetingRepository>(),
      ),
    )
    ..registerFactory<RegisterBloc>(
      () => RegisterBloc(registerService: sl<RegisterService>()),
    );
}

// app.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:ta_client/app/routes/routes.dart';
import 'package:ta_client/core/services/connectivity_service.dart';
import 'package:ta_client/core/services/service_locator.dart';
import 'package:ta_client/core/state/auth_state.dart';
import 'package:ta_client/core/widgets/custom_route_observer.dart';
import 'package:ta_client/features/budgeting/bloc/budgeting_bloc.dart';
import 'package:ta_client/features/budgeting/repositories/budgeting_repository.dart';
import 'package:ta_client/features/evaluation/bloc/evaluation_bloc.dart';
import 'package:ta_client/features/evaluation/repositories/evaluation_repository.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(
            repository: sl<TransactionRepository>(),
            connectivityService: sl<ConnectivityService>(),
            transactionService: sl<TransactionService>(),
          )..add(DashboardReloadRequested()),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(
            repository: sl<TransactionRepository>(),
            connectivityService: sl<ConnectivityService>(),
            transactionService: sl<TransactionService>(),
          ),
        ),
        BlocProvider<BudgetingBloc>(
          create: (context) =>
              BudgetingBloc(repository: sl<BudgetingRepository>()),
        ),
        BlocProvider<EvaluationBloc>(
          create: (context) => EvaluationBloc(
            sl<EvaluationRepository>(),
          ),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthState>(
            create: (_) => sl<AuthState>(),
          ),
        ],
        child: MaterialApp(
          navigatorObservers: [CustomRouteObserver()],
          theme: ThemeData(
            appBarTheme: AppBarTheme(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            useMaterial3: true,
          ),
          initialRoute: Routes.dashboard,
          onGenerateRoute: Routes.generateRoute,
        ),
      ),
    );
  }
}

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
import 'package:ta_client/features/login/bloc/login_bloc.dart';
import 'package:ta_client/features/login/services/login_service.dart';
import 'package:ta_client/features/profile/bloc/profile_bloc.dart';
import 'package:ta_client/features/profile/repositories/profile_repository.dart';
import 'package:ta_client/features/register/bloc/register_bloc.dart';
import 'package:ta_client/features/transaction/bloc/dashboard_bloc.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
import 'package:ta_client/features/transaction/repositories/transaction_hierarchy_repository.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RegisterBloc>(
          create: (context) =>
              sl<RegisterBloc>(),
        ),
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(loginService: sl<LoginService>()),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(
            repository: sl<TransactionRepository>(),
            connectivityService: sl<ConnectivityService>(),
          )..add(DashboardLoadRequested()),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(
            repository: sl<TransactionRepository>(),
            transactionService: sl<TransactionService>(),
            hierarchyRepository: sl<TransactionHierarchyRepository>(),
          ),
        ),
        BlocProvider<BudgetingBloc>(
          create: (context) => BudgetingBloc(sl<BudgetingRepository>()),
        ),
        BlocProvider<EvaluationBloc>(
          create: (context) => EvaluationBloc(sl<EvaluationRepository>()),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(repository: sl<ProfileRepository>()),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthState>(create: (_) => sl<AuthState>()),
        ],
        child: MaterialApp(
          navigatorObservers: [CustomRouteObserver()],
          theme: ThemeData(
            appBarTheme: AppBarTheme(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            ),
            useMaterial3: true,
          ),
          initialRoute: Routes.login,
          onGenerateRoute: Routes.generateRoute,
        ),
      ),
    );
  }
}

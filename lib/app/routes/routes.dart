// routes.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/screens/screens.dart';
import 'package:ta_client/features/profile/view/profile_edit_page.dart';
import 'package:ta_client/features/profile/view/profile_page.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/view/double_entry_recap_page.dart';

class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const otpVerification = '/otp-verification';
  static const dashboard = '/dashboard';
  static const createTransaction = '/create-transaction';
  // static const editTransaction = '/edit-transaction';
  static const viewTransaction = '/view-transaction';
  static const filter = '/filter';
  static const statistik = '/statistik';

  static const evaluationIntro = '/evaluation-intro';
  static const evaluationDateSelection = '/evaluation-date-selection';
  static const evaluationDashboard = '/evaluation-dashboard';
  static const evaluationDetail = '/evaluation-detail';
  static const evaluationHistory = '/evaluation-history';

  static const budgetingIntro = '/budgeting-intro';
  static const budgetingIncome = '/budgeting-income';
  static const budgetingIncomeDate = '/budgeting-income-date';
  static const budgetingAllocationDate = '/budgeting-allocation-date';
  static const budgetingAllocationExpense = '/budgeting-allocation-expense';
  static const budgetingAllocationPage = '/budgeting-allocation-page';
  static const budgetingDashboard = '/budgeting-dashboard';

  static const doubleEntryRecapPage = '/double-entry-recap-page';
  static const profilePage = '/profile';
  static const profileEdit = '/profile/edit';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(
          builder: (_) => WelcomePage.create(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case register:
        return MaterialPageRoute(
          builder: (_) => const RegisterPage(),
          settings: settings,
        );
      case otpVerification:
        return MaterialPageRoute(
          builder: OtpVerificationPage.create, // Use the static create method
          settings: settings,
        );
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
          settings: settings,
        );
      case createTransaction:
        return MaterialPageRoute(
          builder: (_) => const CreateTransactionPage(),
          settings: settings,
        );
      case filter:
        return MaterialPageRoute(
          builder: (_) => const FilterPage(),
          settings: settings,
        );
      case statistik:
        return MaterialPageRoute(
          builder: (_) => const StatisticPieChart(),
          settings: settings,
        );
      case evaluationIntro:
        return MaterialPageRoute(
          builder: (_) => const EvaluationIntroPage(),
          settings: settings,
        );
      case evaluationDateSelection:
        return MaterialPageRoute(
          builder: (_) => const EvaluationDatePage(),
          settings: settings,
        );
      case evaluationDashboard:
        return MaterialPageRoute(
          builder: (_) => const EvaluationDashboardPage(),
          settings: settings,
        );
      case evaluationDetail:
        final id = settings.arguments! as String;
        return MaterialPageRoute(
          builder: (_) => EvaluationDetailPage(id: id),
          settings: settings,
        );
      case evaluationHistory:
        return MaterialPageRoute(
          builder: (_) => const EvaluationHistoryPage(),
          settings: settings,
        );
      case budgetingIntro:
        return MaterialPageRoute(
          builder: (_) => const BudgetingIntro(),
          settings: settings,
        );
      case budgetingIncome:
        return MaterialPageRoute(
          builder: (_) => const BudgetingIncomePage(),
          settings: settings,
        );
      case budgetingIncomeDate:
        return MaterialPageRoute(
          builder: (_) => const BudgetingIncomeDatePage(),
          settings: settings,
        );
      case budgetingAllocationDate:
        return MaterialPageRoute(
          builder: (_) => const BudgetingAllocationDatePage(),
          settings: settings,
        );
      case budgetingAllocationPage:
        return MaterialPageRoute(
          builder: (_) => const BudgetingAllocationPage(),
          settings: settings,
        );
      case budgetingAllocationExpense:
        return MaterialPageRoute(
          builder: (_) => const BudgetingAllocationExpense(),
          settings: settings,
        );
      case budgetingDashboard:
        return MaterialPageRoute(
          builder: (_) => const BudgetingDashboard(),
          settings: settings,
        );
      case doubleEntryRecapPage:
        final txns = settings.arguments! as List<Transaction>;
        return MaterialPageRoute(
          builder: (_) => DoubleEntryRecapPage(transactions: txns),
          settings: settings,
        );
      // case editTransaction:
      //   final transaction = settings.arguments! as Transaction;
      //   return MaterialPageRoute(builder: (_) => EditTransactionPage.create(transaction));
      case viewTransaction:
        final transaction = settings.arguments! as Transaction;
        return MaterialPageRoute(
          builder: (_) => ViewTransactionPage(transaction: transaction),
          settings: settings,
        );
      case profilePage:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
          settings: settings,
        );
      case profileEdit:
        return MaterialPageRoute(
          builder: (_) => const ProfileEditPage(),
          settings: settings,
        );
      default:
        debugPrint('Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
    }
  }
}

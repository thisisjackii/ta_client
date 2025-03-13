// routes.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/screens/screens.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';

class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const otpVerification = '/otp-verification';
  static const dashboard = '/dashboard';
  static const createTransaction = '/create-transaction';
  // static const editTransaction = '/edit-transaction';
  static const viewTransaction = '/view-transaction';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => WelcomePage.create());
      case login:
        return MaterialPageRoute(builder: (_) => LoginPage.create());
      case register:
        return MaterialPageRoute(builder: (_) => RegisterPage.create());
      case otpVerification:
        return MaterialPageRoute(builder: (_) => OtpVerificationPage.create());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case createTransaction:
        return MaterialPageRoute(builder: (_) => const CreateTransactionPage());
      // case editTransaction:
      //   final transaction = settings.arguments! as Transaction;
      //   return MaterialPageRoute(builder: (_) => EditTransactionPage.create(transaction));
      case viewTransaction:
        final transaction = settings.arguments! as Transaction;
        return MaterialPageRoute(builder: (_) => ViewTransactionPage(transaction: transaction));
      default:
        debugPrint('Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}

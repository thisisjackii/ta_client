// routes.dart
import 'package:flutter/material.dart';
import 'package:ta_client/core/screens/screens.dart';

class Routes {
  static const welcome = '/';
  static const login = '/login';
  static const register = '/register';
  static const otpVerification = '/otp-verification';
  static const dashboard = '/dashboard';

  /// This function generates a route based on the given [RouteSettings].
  ///
  /// If the route is not found, it logs a debug message and returns a [MaterialPageRoute]
  /// with a [Scaffold] displaying a 'Page not found' [Text] widget.
  ///
  /// The supported routes are:
  ///
  /// - [welcome]: The welcome page.
  /// - [login]: The login page.
  /// - [register]: The register page.
  /// - [otpVerification]: The OTP verification page.
  /// - [dashboard]: The dashboard page.
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
        return MaterialPageRoute(builder: (_) => DashboardPage.create());
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

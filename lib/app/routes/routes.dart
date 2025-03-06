// routes.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:ta_client/core/screens/screens.dart';

final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://fallback.example.com';

final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'welcome',
      builder: (context, state) => WelcomePage.create(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => LoginPage.create(baseUrl: baseUrl),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => RegisterPage.create(baseUrl: baseUrl),
    ),
    GoRoute(
      path: '/otp-verification',
      name: 'otpVerification',
      builder: (context, state) => OtpVerificationPage.create(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => DashboardPage.create(),
    ),
  ],
  errorBuilder: (context, state) => const Scaffold(
    body: Center(child: Text('Page not found')),
  ),
);

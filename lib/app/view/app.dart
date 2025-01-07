// app.dart
import 'package:flutter/material.dart';
import 'package:ta_client/app/routes/routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  /// The build method of the App widget.
  ///
  /// This method returns a MaterialApp that defines the app's theme and routing.
  ///
  /// The theme is defined with an AppBarTheme that uses the inversePrimary color
  /// scheme color as the background color. The useMaterial3 property is also set
  /// to true.
  ///
  /// The initialRoute is set to Routes.welcome, and the onGenerateRoute is set
  /// to Routes.generateRoute.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      initialRoute: Routes.welcome,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}

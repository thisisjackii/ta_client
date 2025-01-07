import 'package:ta_client/app/app.dart';
import 'package:ta_client/bootstrap.dart';

/// Entry point for the development environment of the application.
///
/// This function initializes the application by calling the `bootstrap`
/// function, which sets up necessary configurations and dependencies,
/// and then runs the `App` widget.
void main() {
  bootstrap(() => const App());
}

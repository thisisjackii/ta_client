import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ta_client/app/app.dart';
import 'package:ta_client/bootstrap.dart';

/// The app's entry point.
///
/// Loads the environment variables from the ".env" file and then starts the
/// app with the [App] widget.
Future<void> main() async {
  await dotenv.load(fileName: '.env.dev');
  await bootstrap(() => const App());
}

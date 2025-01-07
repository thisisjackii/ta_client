import 'package:get_it/get_it.dart';
import 'package:ta_client/core/state/auth_state.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<AuthState>(AuthState.new);
}

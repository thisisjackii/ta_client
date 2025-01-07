import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  /// Called whenever a [Change] occurs in the [bloc].
  ///
  /// This method is triggered when the state of the [bloc] changes. Logs the
  /// type of the [bloc] and the [change] details for debugging purposes.
  ///
  /// The [bloc] parameter is the source of the change, and [change] holds
  /// the details of the state transition.
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  /// Called whenever an error occurs in the [bloc].
  ///
  /// This method logs the error details, including the [bloc] type,
  /// the [error] object, and the [stackTrace]. It provides valuable
  /// information for debugging purposes.
  ///
  /// The [bloc] parameter is the source of the error,
  /// [error] is the exception that was thrown, and [stackTrace]
  /// provides the stack trace at the point where the error was thrown.
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

/// Bootstraps the Flutter application with the provided [builder].
///
/// This function sets up global error handling for Flutter errors by
/// logging them. It also assigns an [AppBlocObserver] to the [Bloc]
/// to observe and log state changes and errors across the application.
///
/// The [builder] function is expected to return the root [Widget] of
/// the application, which will be passed to [runApp].
///
/// This function also provides a place for additional cross-flavor
/// configuration before the application starts.
Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  // Add cross-flavor configuration here

  runApp(await builder());
}

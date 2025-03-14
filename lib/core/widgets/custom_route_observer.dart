import 'package:flutter/material.dart';

class CustomRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> routeStack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routeStack.add(route);
    super.didPush(route, previousRoute);
    debugPrint('Route pushed: ${route.settings.name}');
    debugPrint(
      'Current stack: ${routeStack.map((r) => r.settings.name).toList()}',
    );
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routeStack.remove(route);
    super.didPop(route, previousRoute);
    debugPrint('Route popped: ${route.settings.name}');
    debugPrint(
      'Current stack: ${routeStack.map((r) => r.settings.name).toList()}',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      routeStack.remove(oldRoute);
    }
    if (newRoute != null) {
      routeStack.add(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint(
      'Route replaced: old: ${oldRoute?.settings.name}, new: ${newRoute?.settings.name}',
    );
    debugPrint(
      'Current stack: ${routeStack.map((r) => r.settings.name).toList()}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    routeStack.remove(route);
    super.didRemove(route, previousRoute);
    debugPrint('Route removed: ${route.settings.name}');
    debugPrint(
      'Current stack: ${routeStack.map((r) => r.settings.name).toList()}',
    );
  }
}

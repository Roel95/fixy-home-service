import 'package:flutter/material.dart';

/// Provides a global navigator key so we can trigger navigation
/// from places where a BuildContext may not have access to the
/// top-level navigator (e.g., inside nested navigators or dialogs).
class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Helper getter to access the current global context when available.
  static BuildContext? get context => navigatorKey.currentContext;

  /// Pushes [route] and removes every previous route from the stack.
  static Future<T?> pushAndRemoveAll<T>(Route<T> route) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return Future<T?>.value();
    return navigator.pushAndRemoveUntil(route, (Route<dynamic> _) => false);
  }

  /// Removes any pending snackbars or material banners from the root scaffold.
  static void clearRootScaffold() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..clearSnackBars()
      ..clearMaterialBanners();
  }
}

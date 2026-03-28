import 'package:flutter/material.dart';

/// Slide transition from right (default)
class SlideRightRoute extends PageRouteBuilder {
  final Widget page;

  SlideRightRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}

/// Slide transition from bottom (for modals)
class SlideUpRoute extends PageRouteBuilder {
  final Widget page;

  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;
            var tween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        );
}

/// Fade transition (for dialogs and overlays)
class FadeRoute extends PageRouteBuilder {
  final Widget page;

  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}

/// Scale transition (for popups)
class ScaleRoute extends PageRouteBuilder {
  final Widget page;

  ScaleRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;
            var scaleTween =
                Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: curve));
            var fadeTween =
                Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                  opacity: animation.drive(fadeTween), child: child),
            );
          },
        );
}

/// Combined slide and fade (smooth and professional)
class SlideFadeRoute extends PageRouteBuilder {
  final Widget page;

  SlideFadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.05, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var slideTween =
                Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var fadeTween =
                Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                  opacity: animation.drive(fadeTween), child: child),
            );
          },
        );
}

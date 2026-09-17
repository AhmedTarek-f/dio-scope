import 'package:flutter/material.dart';

import '../../dio_scope.dart';
import '../theme/console_theme.dart';
import 'dio_scope_launcher.dart';

/// Wraps your app with the floating debug launcher.
///
/// Drop it into `MaterialApp.builder` so the launcher floats above every route:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => DioScopeOverlay(child: child!),
///   home: const HomePage(),
/// );
/// ```
///
/// When dio_scope is disabled (release build, or `DioScopeVisibility.disabled`)
/// this returns [child] untouched, so it is safe to leave in production code.
///
/// Tapping the launcher opens the console as a full-screen route on your app's
/// own [Navigator] (located automatically), rather than as a floating layer.
/// That way the OS back button / edge-swipe — including Android's predictive
/// back — closes the console (or an open request/error sheet) natively and
/// never touches the screen behind it, and the console's sheets and dialogs
/// resolve against the app navigator without any navigator key wiring.
class DioScopeOverlay extends StatefulWidget {
  /// The app below the overlay (the `child` from `MaterialApp.builder`).
  final Widget child;

  /// Creates the overlay.
  const DioScopeOverlay({required this.child, super.key});

  @override
  State<DioScopeOverlay> createState() => _DioScopeOverlayState();
}

class _DioScopeOverlayState extends State<DioScopeOverlay> {
  // True while the console route is on screen, so the launcher hides itself
  // instead of floating on top of the open console.
  bool _open = false;

  void _openConsole() {
    if (_open) return;
    final console = DioScope.buildConsole();
    if (console == null) return;
    final navigator = _findHostNavigator();
    if (navigator == null) return;
    final reduceMotion =
        DioScope.options.reduceMotion || MediaQuery.of(context).disableAnimations;

    setState(() => _open = true);
    navigator.push<void>(_consoleRoute(console, reduceMotion)).whenComplete(() {
      if (mounted) setState(() => _open = false);
    });
  }

  // The host Navigator lives inside [DioScopeOverlay.child] (this widget is
  // installed via MaterialApp.builder, which wraps the app's Navigator). Walk
  // down to the first NavigatorState so we can open the console as one of its
  // routes. There is no other Navigator in this subtree, so the first match is
  // the host navigator.
  NavigatorState? _findHostNavigator() {
    NavigatorState? result;
    void visitor(Element element) {
      if (result != null) return;
      if (element is StatefulElement && element.state is NavigatorState) {
        result = element.state as NavigatorState;
        return;
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return result;
  }

  // A full-screen route carrying the design's fade + scale-from-bottom-left
  // entrance. `onClose` is left null so the console's back button pops this
  // route (see ConsoleScreen); the OS back gesture pops it the same way.
  Route<void> _consoleRoute(Widget console, bool reduceMotion) {
    return PageRouteBuilder<void>(
      transitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 340),
      reverseTransitionDuration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) =>
          ColoredBox(color: ConsoleTheme.background, child: console),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: const Cubic(0.2, 0.8, 0.3, 1),
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
            alignment: Alignment.bottomLeft,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!DioScope.isEnabled) return widget.child;
    final options = DioScope.options;
    final reduceMotion =
        options.reduceMotion || MediaQuery.of(context).disableAnimations;

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        if (options.showLauncher && !_open)
          Positioned.fill(
            child: DioScopeLauncher(
              onTap: _openConsole,
              accent: options.accent,
              errorManager: DioScope.errorManager,
              networkManager: DioScope.networkManager,
              liveActivity: options.liveActivity,
              reduceMotion: reduceMotion,
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../dio_scope.dart';
import '../theme/console_theme.dart';
import 'dio_scope_launcher.dart';

/// Wraps your app with the floating debug launcher and the console overlay.
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
/// The console opens as an animated layer hosting its own [Navigator], so it
/// works from `builder` without a navigator key and its sheets/dialogs behave
/// normally.
class DioScopeOverlay extends StatefulWidget {
  /// The app below the overlay (the `child` from `MaterialApp.builder`).
  final Widget child;

  /// Creates the overlay.
  const DioScopeOverlay({required this.child, super.key});

  @override
  State<DioScopeOverlay> createState() => _DioScopeOverlayState();
}

class _DioScopeOverlayState extends State<DioScopeOverlay> {
  bool _open = false;

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
              onTap: () => setState(() => _open = true),
              accent: options.accent,
              errorManager: DioScope.errorManager,
              networkManager: DioScope.networkManager,
              liveActivity: options.liveActivity,
              reduceMotion: reduceMotion,
            ),
          ),
        if (_open)
          Positioned.fill(
            child: _ConsoleOverlay(
              reduceMotion: reduceMotion,
              onClose: () => setState(() => _open = false),
            ),
          ),
      ],
    );
  }
}

class _ConsoleOverlay extends StatefulWidget {
  const _ConsoleOverlay({required this.onClose, required this.reduceMotion});

  final VoidCallback onClose;
  final bool reduceMotion;

  @override
  State<_ConsoleOverlay> createState() => _ConsoleOverlayState();
}

class _ConsoleOverlayState extends State<_ConsoleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  );

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final console = DioScope.buildConsole(onClose: widget.onClose);
    if (console == null) return const SizedBox.shrink();
    final curved = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.2, 0.8, 0.3, 1),
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
        alignment: Alignment.bottomLeft,
        child: ColoredBox(
          color: ConsoleTheme.background,
          // The console runs in its own nested Navigator (so its sheets/dialogs
          // work when opened from MaterialApp.builder). Give it its own hero
          // scope so it doesn't clash with the app's HeroController.
          child: HeroControllerScope.none(
            child: Navigator(
              onGenerateInitialRoutes: (navigator, initialRoute) => [
                MaterialPageRoute<void>(builder: (_) => console),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

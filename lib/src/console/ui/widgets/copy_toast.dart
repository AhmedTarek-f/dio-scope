import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/console_theme.dart';

/// Exposes a `show(message)` function to descendants so any widget can raise a
/// transient copy/confirmation toast. Read it via [ConsoleToastScope.show].
class ConsoleToastScope extends InheritedWidget {
  /// Shows [message] as a toast.
  final void Function(String message) show;

  /// Creates the scope.
  const ConsoleToastScope({
    super.key,
    required this.show,
    required super.child,
  });

  /// Raises a toast with [message] from anywhere below a [ConsoleToastHost].
  static void showMessage(BuildContext context, String message) {
    final scope = context
        .getInheritedWidgetOfExactType<ConsoleToastScope>();
    scope?.show(message);
  }

  @override
  bool updateShouldNotify(ConsoleToastScope oldWidget) => false;
}

/// Hosts the toast overlay for its [child] subtree and provides
/// [ConsoleToastScope]. Toasts auto-dismiss after 1.5s (matching the design).
class ConsoleToastHost extends StatefulWidget {
  /// The subtree that can raise toasts.
  final Widget child;

  /// Creates a toast host.
  const ConsoleToastHost({required this.child, super.key});

  @override
  State<ConsoleToastHost> createState() => _ConsoleToastHostState();
}

class _ConsoleToastHostState extends State<ConsoleToastHost> {
  String? _message;
  int _token = 0;
  Timer? _timer;

  void _show(String message) {
    _timer?.cancel();
    final token = ++_token;
    setState(() => _message = message);
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && token == _token) setState(() => _message = null);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Stack(
      children: [
        ConsoleToastScope(show: _show, child: widget.child),
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: IgnorePointer(
            child: Center(
              child: AnimatedSwitcher(
                duration: t.reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 280),
                switchInCurve: const Cubic(0.2, 1, 0.4, 1),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _message == null
                    ? const SizedBox.shrink(key: ValueKey('none'))
                    : _ToastCard(key: ValueKey(_message), message: _message!),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: ConsoleTheme.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ConsoleTheme.borderHover),
        boxShadow: const [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 17, color: ConsoleTheme.green),
          const SizedBox(width: 9),
          Text(message, style: t.ui(size: 13, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

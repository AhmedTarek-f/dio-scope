import 'package:flutter/widgets.dart';

import '../theme/console_theme.dart';

/// The small pulsing green "Live" dot shown in the console header subtitle.
class LiveDot extends StatefulWidget {
  /// Creates a live dot.
  const LiveDot({super.key});

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ConsoleTheme.of(context).reduceMotion && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = _Dot();
    if (ConsoleTheme.of(context).reduceMotion) return dot;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        return Opacity(
          opacity: 1 - 0.65 * v,
          child: Transform.scale(scale: 1 - 0.28 * v, child: child),
        );
      },
      child: dot,
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: ConsoleTheme.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: ConsoleTheme.green.withValues(alpha: 0.6),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }
}

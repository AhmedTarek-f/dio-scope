import 'package:flutter/widgets.dart';

/// Plays the design's card-entrance once (fade + slight upward slide), after an
/// optional [delay]. Because list items are keyed by id, existing rows keep
/// their state and don't re-animate on stream updates — only new rows animate.
class EntranceAnimation extends StatefulWidget {
  /// The animated child.
  final Widget child;

  /// Delay before the entrance starts (used for the Network stagger).
  final Duration delay;

  /// Skips the animation when true.
  final bool reduceMotion;

  /// Total entrance duration.
  final Duration duration;

  /// Creates an entrance animation.
  const EntranceAnimation({
    required this.child,
    this.delay = Duration.zero,
    this.reduceMotion = false,
    this.duration = const Duration(milliseconds: 340),
    super.key,
  });

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.reduceMotion) {
      _controller.value = 1;
    } else if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, 9 * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

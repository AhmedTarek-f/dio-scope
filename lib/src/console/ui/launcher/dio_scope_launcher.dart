import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../managers/error_manager.dart';
import '../../managers/network_manager.dart';
import '../../models/error_entry.dart';
import '../../models/network_entry.dart';
import '../theme/console_theme.dart';

/// The draggable, edge-snapping floating launcher button.
///
/// Fills its parent (place it in a `Stack`/`Positioned.fill`). Drag it anywhere;
/// on release it snaps to the nearest horizontal edge. A tap (no drag) calls
/// [onTap]. Shows a pulsing red ring + count badge when there are errors, and a
/// cyan activity ring while requests are in flight.
class DioScopeLauncher extends StatefulWidget {
  /// Opens the console.
  final VoidCallback onTap;

  /// Error source (badge + pulse).
  final ErrorManager? errorManager;

  /// Network source (activity ring).
  final NetworkManager? networkManager;

  /// Accent for the FAB gradient.
  final DioScopeAccent accent;

  /// Whether to show the cyan activity ring on in-flight requests.
  final bool liveActivity;

  /// Whether to suppress motion.
  final bool reduceMotion;

  /// Creates the launcher.
  const DioScopeLauncher({
    required this.onTap,
    required this.accent,
    this.errorManager,
    this.networkManager,
    this.liveActivity = true,
    this.reduceMotion = false,
    super.key,
  });

  @override
  State<DioScopeLauncher> createState() => _DioScopeLauncherState();
}

const double _fab = 54;
const double _margin = 14;

class _DioScopeLauncherState extends State<DioScopeLauncher>
    with TickerProviderStateMixin {
  static Offset? _saved;

  Offset? _pos;
  bool _dragging = false;
  bool _moved = false;

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  );
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _float.repeat(reverse: true);
      _ring.repeat();
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _ring.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // Upper clamp bounds are floored at [_margin] so a tiny/zero-size layout pass
  // (which happens on web during bootstrap) never produces lower > upper.
  double _maxX(Size size) => math.max(_margin, size.width - _fab - _margin);
  double _maxY(Size size) => math.max(_margin, size.height - _fab - _margin);

  Offset _initial(Size size) {
    if (_saved != null) return _saved!;
    final y = (size.height - _fab - 120).clamp(_margin, _maxY(size));
    return Offset(_margin, y);
  }

  Offset _clamp(Offset p, Size size) => Offset(
    p.dx.clamp(_margin, _maxX(size)),
    p.dy.clamp(_margin, _maxY(size)),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final pos = _clamp(_pos ?? _initial(size), size);
        return Stack(
          children: [
            AnimatedPositioned(
              duration: _dragging || widget.reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: const Cubic(0.2, 1.2, 0.3, 1),
              left: pos.dx,
              top: pos.dy,
              child: GestureDetector(
                // Reset the drag guard at the start of every gesture. A pure
                // tap never fires onPanStart, so without this a tap that
                // follows a drag would still see `_moved == true` and be
                // swallowed until the State is recreated (app restart).
                onTapDown: (_) => _moved = false,
                onPanStart: (_) => setState(() {
                  _dragging = true;
                  _moved = false;
                  _pos = pos;
                }),
                onPanUpdate: (d) => setState(() {
                  _moved = _moved || d.delta.distance > 0;
                  _pos = _clamp((_pos ?? pos) + d.delta, size);
                }),
                onPanEnd: (_) => setState(() {
                  _dragging = false;
                  final current = _pos ?? pos;
                  final snapLeft = current.dx + _fab / 2 < size.width / 2;
                  _pos = _clamp(
                    Offset(snapLeft ? _margin : size.width - _fab - _margin, current.dy),
                    size,
                  );
                  _saved = _pos;
                }),
                onTap: () {
                  if (!_moved) widget.onTap();
                },
                child: _buildFab(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFab() {
    return StreamBuilder<List<ErrorEntry>>(
      stream: widget.errorManager?.stream,
      initialData: widget.errorManager?.entries ?? const [],
      builder: (context, errSnap) {
        final errCount = errSnap.data?.length ?? 0;
        return StreamBuilder<List<NetworkEntry>>(
          stream: widget.networkManager?.stream,
          initialData: widget.networkManager?.entries ?? const [],
          builder: (context, netSnap) {
            final pending = (netSnap.data ?? const []).any((e) => e.isPending);
            return _fabVisual(errCount: errCount, pending: pending);
          },
        );
      },
    );
  }

  Widget _fabVisual({required int errCount, required bool pending}) {
    final accent = ConsoleTheme(accentKind: widget.accent).accent;
    final showActivity =
        widget.liveActivity && pending && !widget.reduceMotion;
    final showPulse = errCount > 0 && !widget.reduceMotion;

    return AnimatedBuilder(
      animation: Listenable.merge([_float, _ring, _pulse]),
      builder: (context, _) {
        final floatY = widget.reduceMotion || _dragging
            ? 0.0
            : -5 * (1 - (2 * _float.value - 1).abs());
        return Transform.translate(
          offset: Offset(0, floatY),
          child: Transform.scale(
            scale: _dragging ? 1.14 : 1,
            child: SizedBox(
              width: _fab,
              height: _fab,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (showActivity) _activityRing(),
                  if (showPulse) _pulseRing(),
                  Container(
                    width: _fab,
                    height: _fab,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent, ConsoleTheme.violet],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: _dragging ? 0.55 : 0.40),
                          blurRadius: _dragging ? 40 : 26,
                          offset: Offset(0, _dragging ? 18 : 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bug_report, size: 26, color: Colors.white),
                  ),
                  if (errCount > 0)
                    Positioned(top: -6, right: -6, child: _badge(errCount)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _activityRing() {
    final v = _ring.value;
    return Opacity(
      opacity: (0.7 * (1 - v)).clamp(0, 1),
      child: Transform.scale(
        scale: 0.7 + v * 1.4,
        child: Container(
          width: _fab,
          height: _fab,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ConsoleTheme.cyan, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _pulseRing() {
    final v = _pulse.value;
    return Opacity(
      opacity: (0.55 * (1 - v)).clamp(0, 1),
      child: Container(
        width: _fab + v * 26,
        height: _fab + v * 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ConsoleTheme.red.withValues(alpha: 0.55)),
        ),
      ),
    );
  }

  Widget _badge(int count) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(count),
      tween: Tween(begin: 0, end: 1),
      duration: widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 400),
      curve: const Cubic(0.2, 1.3, 0.5, 1),
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        constraints: const BoxConstraints(minWidth: 21),
        height: 21,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ConsoleTheme.red,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: ConsoleTheme.hostBackground, width: 2),
        ),
        child: Text(
          '$count',
          style: ConsoleTheme(accentKind: widget.accent).mono(
            size: 11,
            weight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

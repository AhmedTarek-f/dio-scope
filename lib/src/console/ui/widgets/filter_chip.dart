import 'package:flutter/widgets.dart';

import '../theme/console_theme.dart';

/// A single-select, tinted filter chip with an optional colored dot — used by
/// the Network and Logs filter bars.
class DebugFilterChip extends StatelessWidget {
  /// The chip label.
  final String label;

  /// Whether the chip is selected.
  final bool selected;

  /// The chip's accent color when selected / for its dot.
  final Color color;

  /// Whether to show the 7px colored dot (method chips only).
  final bool showDot;

  /// Tap handler.
  final VoidCallback onTap;

  /// Creates a filter chip.
  const DebugFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.showDot = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final textColor = selected ? color : ConsoleTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: t.reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 180),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : ConsoleTheme.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.45)
                : ConsoleTheme.borderStrong,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: t.ui(size: 12.5, weight: FontWeight.w700, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

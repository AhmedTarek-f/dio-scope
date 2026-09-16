import 'package:flutter/widgets.dart';

import '../theme/console_theme.dart';

/// The centered empty-state used by every tab: a rounded icon tile, a title,
/// and a muted body line.
class EmptyState extends StatelessWidget {
  /// The tile icon.
  final IconData icon;

  /// The bold title.
  final String title;

  /// The muted supporting line.
  final String message;

  /// When true, renders the green "success" variant (Errors tab, no errors).
  final bool success;

  /// Creates an empty state.
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.success = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final tileColor = success
        ? ConsoleTheme.green.withValues(alpha: 0.09)
        : ConsoleTheme.emptyIconTile;
    final tileBorder = success
        ? ConsoleTheme.green.withValues(alpha: 0.25)
        : ConsoleTheme.border;
    final iconColor = success ? ConsoleTheme.green : ConsoleTheme.mutedDimmer;
    final tileSize = success ? 78.0 : 74.0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: tileColor,
                borderRadius: BorderRadius.circular(success ? 24 : 22),
                border: Border.all(color: tileBorder),
              ),
              child: Icon(icon, size: success ? 36 : 34, color: iconColor),
            ),
            const SizedBox(height: 18),
            Text(title, style: t.ui(size: 16, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 250),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: t.ui(
                  size: 13,
                  color: ConsoleTheme.muted,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

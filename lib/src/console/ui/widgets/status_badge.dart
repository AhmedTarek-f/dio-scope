import 'package:flutter/widgets.dart';

import '../theme/console_theme.dart';

/// A tinted HTTP status-code pill. Shows `···` while pending.
class StatusBadge extends StatelessWidget {
  /// The status code, or `null` while the request is pending.
  final int? status;

  /// Whether to render the larger sheet-header variant.
  final bool large;

  /// Creates a status badge.
  const StatusBadge(this.status, {this.large = false, super.key});

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final color = t.statusColor(status);
    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 11, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: t.tinted(color, bg: 0.13, border: 0.32, radius: large ? 8 : 7),
      child: Text(
        status?.toString() ?? '···',
        style: t.mono(size: large ? 13 : 12, weight: FontWeight.w800, color: color),
      ),
    );
  }
}

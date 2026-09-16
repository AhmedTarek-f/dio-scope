import 'package:flutter/widgets.dart';

import '../theme/console_theme.dart';

/// A tinted HTTP-method pill (GET/POST/…), colored per the design.
class MethodBadge extends StatelessWidget {
  /// The HTTP method text.
  final String method;

  /// Creates a method badge.
  const MethodBadge(this.method, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final color = t.methodColor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: t.tinted(color, bg: 0.14, border: 0.30, radius: 7),
      child: Text(
        method.toUpperCase(),
        style: t.mono(
          size: 11,
          weight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/console_theme.dart';
import 'copy_toast.dart';

/// Copies [text] to the clipboard and raises a toast when tapped.
void _copy(BuildContext context, String text, String toast) {
  Clipboard.setData(ClipboardData(text: text));
  ConsoleToastScope.showMessage(context, toast);
}

/// A compact icon-only copy button.
class CopyButton extends StatelessWidget {
  /// The text copied on tap.
  final String text;

  /// The toast shown after copying.
  final String toast;

  /// The icon size.
  final double size;

  /// Creates an icon copy button.
  const CopyButton({
    required this.text,
    this.toast = 'Copied to clipboard',
    this.size = 15,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copy(context, text, toast),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.content_copy,
          size: size,
          color: ConsoleTheme.mutedDimmer,
        ),
      ),
    );
  }
}

/// A labeled copy button: either a bordered "Copy" pill or an accent text link.
class CopyLabelButton extends StatelessWidget {
  /// The text copied on tap.
  final String text;

  /// The button label.
  final String label;

  /// The toast shown after copying.
  final String toast;

  /// When true, renders as an accent-colored text link (used for body copies).
  final bool accentLink;

  /// Creates a labeled copy button.
  const CopyLabelButton({
    required this.text,
    this.label = 'Copy',
    this.toast = 'Copied to clipboard',
    this.accentLink = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    if (accentLink) {
      return GestureDetector(
        onTap: () => _copy(context, text, toast),
        behavior: HitTestBehavior.opaque,
        child: Text(
          label,
          style: t.ui(size: 11, weight: FontWeight.w700, color: t.accent),
        ),
      );
    }
    return GestureDetector(
      onTap: () => _copy(context, text, toast),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ConsoleTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ConsoleTheme.borderStrong),
        ),
        child: Text(
          label,
          style: t.ui(
            size: 11,
            weight: FontWeight.w700,
            color: ConsoleTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

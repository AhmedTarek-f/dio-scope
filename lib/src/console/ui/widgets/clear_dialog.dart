import 'package:flutter/material.dart';

import '../theme/console_theme.dart';

/// Shows the "Clear debug data?" confirmation dialog with the design's
/// scale+fade entrance. Returns `true` when the user confirms.
Future<bool> showClearDialog(BuildContext context, ConsoleTheme theme) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Clear debug data',
    barrierColor: const Color(0xA8030509),
    transitionDuration: theme.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => ConsoleThemeScope(
      theme: theme,
      child: const Center(child: _ClearDialogCard()),
    ),
    transitionBuilder: (context, anim, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: const Cubic(0.2, 1, 0.4, 1),
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
  return result ?? false;
}

class _ClearDialogCard extends StatelessWidget {
  const _ClearDialogCard();

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(26),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ConsoleTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: ConsoleTheme.borderStrong),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 70,
                  offset: Offset(0, 30),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: ConsoleTheme.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: ConsoleTheme.red.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 24,
                    color: ConsoleTheme.red,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Clear debug data?',
                  style: t.ui(size: 18, weight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'This removes all captured requests, logs, errors and '
                  'variables for this session. This cannot be undone.',
                  style: t.ui(
                    size: 13.5,
                    color: ConsoleTheme.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: 'Cancel',
                        background: ConsoleTheme.elevated,
                        border: const Color(0xFF2A3546),
                        textColor: ConsoleTheme.textPrimary,
                        weight: FontWeight.w700,
                        onTap: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DialogButton(
                        label: 'Clear all',
                        background: ConsoleTheme.red,
                        textColor: Colors.white,
                        weight: FontWeight.w800,
                        onTap: () => Navigator.of(context).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.weight,
    required this.onTap,
    this.border,
  });

  final String label;
  final Color background;
  final Color? border;
  final Color textColor;
  final FontWeight weight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: border == null ? null : Border.all(color: border!),
        ),
        child: Text(
          label,
          style: t.ui(size: 14, weight: weight, color: textColor),
        ),
      ),
    );
  }
}

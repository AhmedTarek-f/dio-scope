import 'package:flutter/material.dart';

import '../theme/console_theme.dart';

/// The dark, rounded search field used by the Network and Logs filter bars.
class DebugSearchBar extends StatelessWidget {
  /// The field controller.
  final TextEditingController controller;

  /// Placeholder text.
  final String hint;

  /// Called on every change (and on clear).
  final ValueChanged<String> onChanged;

  /// Creates a search bar.
  const DebugSearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: ConsoleTheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: ConsoleTheme.borderStrong),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 17, color: ConsoleTheme.muted),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              cursorColor: t.accent,
              style: t.ui(size: 14),
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: t.ui(size: 14, color: ConsoleTheme.muted),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: ConsoleTheme.borderStrong,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: ConsoleTheme.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

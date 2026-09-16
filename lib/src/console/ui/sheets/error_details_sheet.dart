import 'package:flutter/material.dart';

import '../../models/error_entry.dart';
import '../theme/console_theme.dart';
import '../widgets/copy_button.dart';
import '../widgets/copy_toast.dart';

/// Opens the Error Details bottom sheet for [entry].
void showErrorDetailsSheet(
  BuildContext context,
  ErrorEntry entry,
  ConsoleTheme theme,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x99030509),
    builder: (_) => ConsoleThemeScope(
      theme: theme,
      child: ConsoleToastHost(child: _ErrorSheet(entry: entry)),
    ),
  );
}

class _ErrorSheet extends StatelessWidget {
  const _ErrorSheet({required this.entry});

  final ErrorEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final color = t.severityColor(entry.severity);
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: ConsoleTheme.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: ConsoleTheme.borderStrong)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: ConsoleTheme.handle,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          _header(context, t, color),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  entry.title,
                  style: t.ui(size: 17, weight: FontWeight.w800, color: ConsoleTheme.textDim1, height: 1.35),
                ),
                if (entry.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(entry.subtitle!, style: t.ui(size: 13, color: ConsoleTheme.textSecondary)),
                ],
                const SizedBox(height: 15),
                // Wrapped in IntrinsicHeight so the equal-height tiles
                // (crossAxisAlignment.stretch) have a bounded cross-axis extent:
                // this Row lives inside a ListView, which offers unbounded
                // height, and stretch alone would force the tiles to infinity.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _tile(t, 'Source', entry.source ?? 'unknown',
                            color: ConsoleTheme.textDim2, mono: true),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _tile(t, 'Severity', entry.severity.severityLabel, color: color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Text('STACK TRACE',
                        style: t.ui(size: 12, weight: FontWeight.w800, color: ConsoleTheme.muted, letterSpacing: 0.7)),
                    const Spacer(),
                    CopyLabelButton(text: entry.stackTrace ?? '', label: 'Copy trace'),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: ConsoleTheme.codeGround,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: ConsoleTheme.borderFaint),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text.rich(
                      _stackSpans(t, entry.stackTrace ?? 'No stack trace available'),
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, ConsoleTheme t, Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ConsoleTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: t.tinted(color, bg: 0.13, border: 0.30, radius: 8),
            child: Text(
              entry.severity.label,
              style: t.ui(size: 12, weight: FontWeight.w800, color: color, letterSpacing: 0.3),
            ),
          ),
          const SizedBox(width: 10),
          Text(entry.relativeTime, style: t.mono(size: 11, color: ConsoleTheme.muted)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: ConsoleTheme.elevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, size: 18, color: ConsoleTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(ConsoleTheme t, String label, String value, {required Color color, bool mono = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: ConsoleTheme.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: ConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.ui(size: 11, weight: FontWeight.w700, color: ConsoleTheme.muted)),
          const SizedBox(height: 4),
          mono
              ? Text(value, style: t.mono(size: 12.5, weight: FontWeight.w700, color: color))
              : Text(value, style: t.ui(size: 12.5, weight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  TextSpan _stackSpans(ConsoleTheme t, String trace) {
    final lines = trace.split('\n');
    final base = t.mono(size: 12, height: 1.75);
    var firstNonEmptySeen = false;
    final spans = <TextSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      Color color = ConsoleTheme.textSecondary;
      final trimmed = line.trimLeft();
      if (!firstNonEmptySeen && trimmed.isNotEmpty) {
        color = const Color(0xFFF87171);
        firstNonEmptySeen = true;
      } else if (trimmed.startsWith('<asynchronous')) {
        color = ConsoleTheme.violet;
      } else if (trimmed.startsWith('Response:')) {
        color = ConsoleTheme.jsonString;
      } else if (RegExp(r'^#\d').hasMatch(trimmed)) {
        color = ConsoleTheme.muted;
      }
      spans.add(TextSpan(
        text: i == lines.length - 1 ? line : '$line\n',
        style: base.copyWith(color: color),
      ));
    }
    return TextSpan(children: spans);
  }
}

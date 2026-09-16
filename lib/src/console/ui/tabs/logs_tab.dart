import 'package:flutter/material.dart';

import '../../managers/log_manager.dart';
import '../../models/log_entry.dart';
import '../theme/console_theme.dart';
import '../widgets/copy_button.dart';
import '../widgets/copy_toast.dart';
import '../widgets/empty_state.dart';
import '../widgets/entrance.dart';
import '../widgets/filter_chip.dart';
import '../widgets/search_bar.dart';

/// The Logs tab: a terminal-style, filterable stream of app log lines.
class LogsTab extends StatefulWidget {
  /// The log manager providing entries.
  final LogManager manager;

  /// Whether the filter bar is expanded.
  final bool showFilters;

  /// Creates the Logs tab.
  const LogsTab({required this.manager, required this.showFilters, super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  final _search = TextEditingController();
  String _query = '';
  LogLevel? _level;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(LogEntry e) {
    if (_level != null && e.level != _level) return false;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      return e.message.toLowerCase().contains(q) ||
          (e.tag?.toLowerCase().contains(q) ?? false);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Column(
      children: [
        _FilterBar(
          visible: widget.showFilters,
          search: _search,
          level: _level,
          onSearch: (v) => setState(() => _query = v),
          onLevel: (l) => setState(() => _level = l),
          onClear: () {
            widget.manager.clear();
            ConsoleToastScope.showMessage(context, 'Logs cleared');
          },
        ),
        Expanded(
          child: ColoredBox(
            color: ConsoleTheme.codeGround,
            child: StreamBuilder<List<LogEntry>>(
              stream: widget.manager.stream,
              initialData: widget.manager.entries,
              builder: (context, snapshot) {
                final all = snapshot.data ?? const [];
                final filtered = all.where(_matches).toList();
                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notes,
                    title: 'No logs to show',
                    message:
                        'Debug, info, warning and error logs will stream here as your app runs.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 26),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final entry = filtered[i];
                    return Dismissible(
                      key: ValueKey(entry),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => widget.manager.removeEntry(entry),
                      background: const ColoredBox(color: Color(0x22EF4444)),
                      child: EntranceAnimation(
                        duration: const Duration(milliseconds: 300),
                        reduceMotion: t.reduceMotion,
                        child: _LogRow(entry: entry),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.visible,
    required this.search,
    required this.level,
    required this.onSearch,
    required this.onLevel,
    required this.onClear,
  });

  final bool visible;
  final TextEditingController search;
  final LogLevel? level;
  final ValueChanged<String> onSearch;
  final ValueChanged<LogLevel?> onLevel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return AnimatedSize(
      duration: t.reduceMotion ? Duration.zero : const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: DebugSearchBar(
                    controller: search,
                    hint: 'Search logs…',
                    onChanged: onSearch,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      DebugFilterChip(
                        label: 'All',
                        selected: level == null,
                        color: t.accent,
                        onTap: () => onLevel(null),
                      ),
                      const SizedBox(width: 8),
                      for (final l in LogLevel.values) ...[
                        DebugFilterChip(
                          label: l.name.toUpperCase(),
                          selected: level == l,
                          color: t.logLevelColor(l),
                          showDot: true,
                          onTap: () => onLevel(l),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _ClearChip(onTap: onClear),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ClearChip extends StatelessWidget {
  const _ClearChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ConsoleTheme.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0xFF2A1417)),
        ),
        child: Text(
          'Clear',
          style: t.ui(size: 12, weight: FontWeight.w700, color: ConsoleTheme.red),
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final color = t.logLevelColor(entry.level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color.withValues(alpha: 0.55), width: 2.5),
          bottom: const BorderSide(color: ConsoleTheme.borderFaintest),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              entry.formattedTime,
              style: t.mono(size: 11, color: ConsoleTheme.mutedDim, letterSpacing: -0.3),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 58,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: t.tinted(color, bg: 0.14, border: null, radius: 5),
            child: Text(
              entry.level.name.toUpperCase(),
              style: t.mono(
                size: 9.5,
                weight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.tag != null ? '${entry.message}  [${entry.tag}]' : entry.message,
              style: t.mono(size: 12.5, color: ConsoleTheme.textDim3, height: 1.55),
            ),
          ),
          const SizedBox(width: 6),
          CopyButton(text: entry.message, size: 15),
        ],
      ),
    );
  }
}

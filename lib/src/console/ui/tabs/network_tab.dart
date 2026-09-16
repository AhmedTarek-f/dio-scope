import 'package:flutter/material.dart';

import '../../managers/network_manager.dart';
import '../../models/network_entry.dart';
import '../sheets/request_details_sheet.dart';
import '../theme/console_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/entrance.dart';
import '../widgets/filter_chip.dart';
import '../widgets/method_badge.dart';
import '../widgets/search_bar.dart';
import '../widgets/status_badge.dart';

/// The Network tab: a searchable/filterable list of captured requests.
class NetworkTab extends StatefulWidget {
  /// The network manager providing entries.
  final NetworkManager manager;

  /// Whether the filter bar is expanded.
  final bool showFilters;

  /// Creates the Network tab.
  const NetworkTab({required this.manager, required this.showFilters, super.key});

  @override
  State<NetworkTab> createState() => _NetworkTabState();
}

class _NetworkTabState extends State<NetworkTab> {
  final _search = TextEditingController();
  String _query = '';
  String _filter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(NetworkEntry e) {
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      final hit =
          e.path.toLowerCase().contains(q) ||
          e.method.toLowerCase().contains(q) ||
          (e.statusCode?.toString().contains(q) ?? false);
      if (!hit) return false;
    }
    final s = e.statusCode;
    return switch (_filter) {
      'all' => true,
      '2xx' => s != null && s >= 200 && s < 300,
      '3xx' => s != null && s >= 300 && s < 400,
      '4xx' => s != null && s >= 400 && s < 500,
      '5xx' => s != null && s >= 500,
      'errors' => e.isFailure,
      _ => e.method.toUpperCase() == _filter,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Column(
      children: [
        _FilterBar(
          visible: widget.showFilters,
          search: _search,
          selected: _filter,
          onSearch: (v) => setState(() => _query = v),
          onFilter: (f) => setState(() => _filter = f),
        ),
        Expanded(
          child: StreamBuilder<List<NetworkEntry>>(
            stream: widget.manager.stream,
            initialData: widget.manager.entries,
            builder: (context, snapshot) {
              final all = snapshot.data ?? const [];
              final filtered = all.where(_matches).toList();
              if (filtered.isEmpty) {
                final filtering = _query.isNotEmpty || _filter != 'all';
                return EmptyState(
                  icon: Icons.wifi,
                  title: filtering
                      ? 'No matching requests'
                      : 'No network requests yet',
                  message: filtering
                      ? 'Try a different filter or search term to see captured requests.'
                      : 'API calls will appear here when your application talks to a server.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 26),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final entry = filtered[i];
                  return Padding(
                    key: ValueKey(entry.id),
                    padding: const EdgeInsets.only(bottom: 10),
                    child: EntranceAnimation(
                      delay: Duration(milliseconds: (i * 45).clamp(0, 260)),
                      reduceMotion: t.reduceMotion,
                      child: _RequestCard(entry: entry),
                    ),
                  );
                },
              );
            },
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
    required this.selected,
    required this.onSearch,
    required this.onFilter,
  });

  final bool visible;
  final TextEditingController search;
  final String selected;
  final ValueChanged<String> onSearch;
  final ValueChanged<String> onFilter;

  static const _chips = <(String, String, bool)>[
    ('All', 'all', false),
    ('GET', 'GET', true),
    ('POST', 'POST', true),
    ('PUT', 'PUT', true),
    ('PATCH', 'PATCH', true),
    ('DELETE', 'DELETE', true),
    ('2xx', '2xx', false),
    ('3xx', '3xx', false),
    ('4xx', '4xx', false),
    ('5xx', '5xx', false),
    ('Errors', 'errors', false),
  ];

  Color _chipColor(ConsoleTheme t, String key) => switch (key) {
    'all' => t.accent,
    'GET' => ConsoleTheme.green,
    'POST' => ConsoleTheme.blue,
    'PUT' => ConsoleTheme.amber,
    'PATCH' => ConsoleTheme.violet,
    'DELETE' => ConsoleTheme.red,
    '2xx' => ConsoleTheme.green,
    '3xx' => ConsoleTheme.cyan,
    '4xx' => ConsoleTheme.amber,
    '5xx' => ConsoleTheme.red,
    'errors' => ConsoleTheme.red,
    _ => ConsoleTheme.textSecondary,
  };

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
                    hint: 'Search URL, endpoint, status…',
                    onChanged: onSearch,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    children: [
                      for (final c in _chips) ...[
                        DebugFilterChip(
                          label: c.$1,
                          selected: selected == c.$2,
                          color: _chipColor(t, c.$2),
                          showDot: c.$3,
                          onTap: () => onFilter(c.$2),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.entry});

  final NetworkEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return GestureDetector(
      onTap: () => showRequestDetailsSheet(context, entry, t),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ConsoleTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: entry.isFailure
                ? ConsoleTheme.red.withValues(alpha: 0.28)
                : ConsoleTheme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MethodBadge(entry.method),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.path,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.mono(
                      size: 13,
                      weight: FontWeight.w500,
                      color: ConsoleTheme.textDim2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (entry.isPending)
                  const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ConsoleTheme.cyan,
                      backgroundColor: Color(0xFF222233),
                    ),
                  )
                else
                  StatusBadge(entry.statusCode),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  entry.formattedTime,
                  style: t.mono(size: 11, color: ConsoleTheme.muted),
                ),
                const SizedBox(width: 10),
                Expanded(child: _DurationBar(entry: entry)),
                const SizedBox(width: 10),
                Text(
                  entry.durationLabel,
                  style: t.mono(
                    size: 11,
                    weight: FontWeight.w700,
                    color: t.durationColor(entry.duration),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationBar extends StatelessWidget {
  const _DurationBar({required this.entry});

  final NetworkEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final pending = entry.isPending;
    final ms = entry.duration?.inMilliseconds ?? 0;
    final fraction = pending ? 1.0 : (ms / 2000).clamp(0.07, 1.0);
    final color = t.durationColor(entry.duration);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 4,
        color: ConsoleTheme.borderFaint,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction),
            duration: t.reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 500),
            curve: const Cubic(0.2, 0.8, 0.3, 1),
            builder: (context, value, _) => FractionallySizedBox(
              widthFactor: value,
              child: Opacity(
                opacity: pending ? 0.5 : 1,
                child: Container(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

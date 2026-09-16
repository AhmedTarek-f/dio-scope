import 'package:flutter/material.dart';

import '../config.dart';
import '../data/system_info_collector.dart';
import '../managers/error_manager.dart';
import '../managers/log_manager.dart';
import '../managers/network_manager.dart';
import '../models/error_entry.dart';
import '../models/network_entry.dart';
import 'tabs/errors_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/network_tab.dart';
import 'tabs/system_tab.dart';
import 'theme/console_theme.dart';
import 'widgets/clear_dialog.dart';
import 'widgets/copy_toast.dart';
import 'widgets/live_dot.dart';

/// The full-screen debug console: header, tab bar, and the four tabs.
class ConsoleScreen extends StatefulWidget {
  /// The network capture manager.
  final NetworkManager networkManager;

  /// The log manager.
  final LogManager logManager;

  /// The error manager.
  final ErrorManager errorManager;

  /// The system-info collector.
  final SystemInfoCollector systemInfoCollector;

  /// Console options (accent, motion, capacities).
  final DebugConsoleOptions options;

  /// Called by the back button. When null, the screen pops its route instead
  /// (used when opened as a route via `DioScope.showConsole`).
  final VoidCallback? onClose;

  /// Creates the console screen.
  const ConsoleScreen({
    required this.networkManager,
    required this.logManager,
    required this.errorManager,
    required this.systemInfoCollector,
    required this.options,
    this.onClose,
    super.key,
  });

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

enum _Tab { network, logs, errors, system }

class _ConsoleScreenState extends State<ConsoleScreen> {
  _Tab _tab = _Tab.network;
  bool _showFilters = true;

  bool get _filtersApply => _tab == _Tab.network || _tab == _Tab.logs;

  Future<void> _handleClear(ConsoleTheme theme) async {
    final confirmed = await showClearDialog(context, theme);
    if (!confirmed || !mounted) return;
    widget.networkManager.clear();
    widget.logManager.clear();
    widget.errorManager.clear();
    if (mounted) {
      ConsoleToastScope.showMessage(context, 'All debug data cleared');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        widget.options.reduceMotion || MediaQuery.of(context).disableAnimations;
    final theme = ConsoleTheme(
      accentKind: widget.options.accent,
      reduceMotion: reduceMotion,
    );

    return ConsoleThemeScope(
      theme: theme,
      child: Scaffold(
        backgroundColor: ConsoleTheme.background,
        body: ConsoleToastHost(
          child: SafeArea(
            child: Column(
              children: [
                _Header(
                  networkStream: widget.networkManager.stream,
                  errorStream: widget.errorManager.stream,
                  networkSeed: widget.networkManager.entries,
                  errorSeed: widget.errorManager.entries,
                  showFilters: _showFilters,
                  onBack:
                      widget.onClose ??
                      () => Navigator.of(context).maybePop(),
                  onToggleFilters: () =>
                      setState(() => _showFilters = !_showFilters),
                  onClear: () => _handleClear(theme),
                ),
                _TabBar(
                  current: _tab,
                  errorStream: widget.errorManager.stream,
                  errorSeed: widget.errorManager.entries,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.06),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: _buildTab(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tab) {
      case _Tab.network:
        return NetworkTab(
          manager: widget.networkManager,
          showFilters: _showFilters && _filtersApply,
        );
      case _Tab.logs:
        return LogsTab(
          manager: widget.logManager,
          showFilters: _showFilters && _filtersApply,
        );
      case _Tab.errors:
        return ErrorsTab(manager: widget.errorManager);
      case _Tab.system:
        return SystemTab(collector: widget.systemInfoCollector);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.networkStream,
    required this.errorStream,
    required this.networkSeed,
    required this.errorSeed,
    required this.showFilters,
    required this.onBack,
    required this.onToggleFilters,
    required this.onClear,
  });

  final Stream<List<NetworkEntry>> networkStream;
  final Stream<List<ErrorEntry>> errorStream;
  final List<NetworkEntry> networkSeed;
  final List<ErrorEntry> errorSeed;
  final bool showFilters;
  final VoidCallback onBack;
  final VoidCallback onToggleFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ConsoleTheme.borderFaint),
        ),
      ),
      child: Row(
        children: [
          _HeaderIconButton(
            icon: Icons.arrow_back,
            onTap: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Debug Console',
                  style: t.ui(
                    size: 17,
                    weight: FontWeight.w800,
                    letterSpacing: -0.2,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 2),
                _LiveSubtitle(
                  networkStream: networkStream,
                  errorStream: errorStream,
                  networkSeed: networkSeed,
                  errorSeed: errorSeed,
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.filter_alt_outlined,
            active: showFilters,
            onTap: onToggleFilters,
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.delete_outline,
            danger: true,
            onTap: onClear,
          ),
        ],
      ),
    );
  }
}

class _LiveSubtitle extends StatelessWidget {
  const _LiveSubtitle({
    required this.networkStream,
    required this.errorStream,
    required this.networkSeed,
    required this.errorSeed,
  });

  final Stream<List<NetworkEntry>> networkStream;
  final Stream<List<ErrorEntry>> errorStream;
  final List<NetworkEntry> networkSeed;
  final List<ErrorEntry> errorSeed;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return StreamBuilder<List<NetworkEntry>>(
      stream: networkStream,
      initialData: networkSeed,
      builder: (context, netSnap) {
        final reqCount = netSnap.data?.length ?? 0;
        return StreamBuilder<List<ErrorEntry>>(
          stream: errorStream,
          initialData: errorSeed,
          builder: (context, errSnap) {
            final errCount = errSnap.data?.length ?? 0;
            final dot = t.mono(size: 11.5, color: ConsoleTheme.handle);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LiveDot(),
                const SizedBox(width: 7),
                Text(
                  'Live',
                  style: t.ui(
                    size: 11.5,
                    weight: FontWeight.w700,
                    color: ConsoleTheme.green,
                  ),
                ),
                Text('  ·  ', style: dot),
                Text(
                  '$reqCount',
                  style: t.mono(size: 11.5, color: ConsoleTheme.textSecondary),
                ),
                Text(
                  ' req',
                  style: t.ui(size: 11.5, color: ConsoleTheme.textSecondary),
                ),
                Text('  ·  ', style: dot),
                Text(
                  '$errCount',
                  style: t.mono(
                    size: 11.5,
                    color: errCount > 0
                        ? ConsoleTheme.red
                        : ConsoleTheme.green,
                  ),
                ),
                Text(
                  ' err',
                  style: t.ui(size: 11.5, color: ConsoleTheme.textSecondary),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    Color background;
    Color iconColor;
    Color borderColor;
    if (danger) {
      background = ConsoleTheme.red.withValues(alpha: 0.08);
      iconColor = ConsoleTheme.red;
      borderColor = const Color(0xFF2A1417);
    } else if (active) {
      background = t.accent.withValues(alpha: 0.14);
      iconColor = t.accent;
      borderColor = ConsoleTheme.borderStrong;
    } else {
      background = ConsoleTheme.surface;
      iconColor = ConsoleTheme.textSecondary;
      borderColor = ConsoleTheme.borderStrong;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, size: 19, color: iconColor),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.current,
    required this.errorStream,
    required this.errorSeed,
    required this.onChanged,
  });

  final _Tab current;
  final Stream<List<ErrorEntry>> errorStream;
  final List<ErrorEntry> errorSeed;
  final ValueChanged<_Tab> onChanged;

  static const _defs = <(_Tab, IconData, String)>[
    (_Tab.network, Icons.wifi, 'Network'),
    (_Tab.logs, Icons.notes, 'Logs'),
    (_Tab.errors, Icons.warning_amber_rounded, 'Errors'),
    (_Tab.system, Icons.info_outline, 'System'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final index = _defs.indexWhere((d) => d.$1 == current);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ConsoleTheme.borderFaint),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = constraints.maxWidth / _defs.length;
          const indicatorWidth = 44.0;
          return Stack(
            children: [
              Row(
                children: [
                  for (final def in _defs)
                    SizedBox(
                      width: slot,
                      child: _TabItem(
                        icon: def.$2,
                        label: def.$3,
                        active: def.$1 == current,
                        showBadge: def.$1 == _Tab.errors,
                        errorStream: errorStream,
                        errorSeed: errorSeed,
                        onTap: () => onChanged(def.$1),
                      ),
                    ),
                ],
              ),
              AnimatedPositioned(
                duration: t.reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: const Cubic(0.4, 0, 0.2, 1),
                bottom: 0,
                left: index * slot + (slot - indicatorWidth) / 2,
                width: indicatorWidth,
                height: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(99),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: t.accent.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.showBadge,
    required this.errorStream,
    required this.errorSeed,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool showBadge;
  final Stream<List<ErrorEntry>> errorStream;
  final List<ErrorEntry> errorSeed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final color = active ? t.accent : ConsoleTheme.muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 21, color: color),
                if (showBadge)
                  Positioned(
                    top: -6,
                    right: -11,
                    child: _ErrorBadge(
                      errorStream: errorStream,
                      errorSeed: errorSeed,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: t.ui(size: 12, weight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBadge extends StatelessWidget {
  const _ErrorBadge({required this.errorStream, required this.errorSeed});

  final Stream<List<ErrorEntry>> errorStream;
  final List<ErrorEntry> errorSeed;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return StreamBuilder<List<ErrorEntry>>(
      stream: errorStream,
      initialData: errorSeed,
      builder: (context, snap) {
        final count = snap.data?.length ?? 0;
        if (count == 0) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(minWidth: 16),
          height: 16,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ConsoleTheme.red,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            '$count',
            style: t.mono(size: 10, weight: FontWeight.w800, color: Colors.white),
          ),
        );
      },
    );
  }
}

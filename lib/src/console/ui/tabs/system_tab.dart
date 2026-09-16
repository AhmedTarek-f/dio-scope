import 'package:flutter/material.dart';

import '../../data/system_info_collector.dart';
import '../theme/console_theme.dart';
import '../widgets/copy_button.dart';

/// The System tab: grouped application / device / runtime information.
class SystemTab extends StatefulWidget {
  /// The collector providing system info.
  final SystemInfoCollector collector;

  /// Creates the System tab.
  const SystemTab({required this.collector, super.key});

  @override
  State<SystemTab> createState() => _SystemTabState();
}

class _SystemTabState extends State<SystemTab> {
  late final Future<List<SystemInfoGroup>> _future = widget.collector.collect();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SystemInfoGroup>>(
      future: _future,
      builder: (context, snapshot) {
        final groups = snapshot.data ?? const [];
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            for (final group in groups) ...[
              if (group.colorKey == 'push')
                _TokenGroup(group: group)
              else
                _Group(group: group),
              const SizedBox(height: 13),
            ],
          ],
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group});

  final SystemInfoGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: ConsoleTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ConsoleTheme.border),
      ),
      child: Column(
        children: [
          _GroupHeader(title: group.title, colorKey: group.colorKey),
          for (final row in group.rows) _Row(row: row),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.colorKey});

  final String title;
  final String colorKey;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ConsoleTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: t.groupDotColor(colorKey),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title.toUpperCase(),
            style: t.ui(
              size: 12,
              weight: FontWeight.w800,
              color: ConsoleTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.row});

  final SystemInfoRow row;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ConsoleTheme.borderSubtle)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label,
            style: t.ui(size: 13, weight: FontWeight.w600, color: ConsoleTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Align(alignment: Alignment.centerRight, child: _value(t))),
          const SizedBox(width: 8),
          CopyButton(text: row.value, size: 14),
        ],
      ),
    );
  }

  Widget _value(ConsoleTheme t) {
    switch (row.style) {
      case SystemValueStyle.tagGood:
      case SystemValueStyle.tagWarn:
      case SystemValueStyle.tagInfo:
        final color = switch (row.style) {
          SystemValueStyle.tagGood => ConsoleTheme.green,
          SystemValueStyle.tagWarn => ConsoleTheme.amber,
          _ => ConsoleTheme.cyan,
        };
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: t.tinted(color, bg: 0.14, border: 0.32, radius: 99),
          child: Text(
            row.value,
            style: t.ui(size: 12, weight: FontWeight.w800, color: color),
          ),
        );
      case SystemValueStyle.mono:
        return Text(
          row.value,
          textAlign: TextAlign.right,
          style: t.mono(size: 13.5, weight: FontWeight.w700, color: ConsoleTheme.textDim1, letterSpacing: -0.2),
        );
      case SystemValueStyle.plain:
        return Text(
          row.value,
          textAlign: TextAlign.right,
          style: t.ui(size: 13.5, weight: FontWeight.w700, color: ConsoleTheme.textDim1),
        );
    }
  }
}

class _TokenGroup extends StatelessWidget {
  const _TokenGroup({required this.group});

  final SystemInfoGroup group;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final token = group.rows.isNotEmpty ? group.rows.first.value : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: ConsoleTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ConsoleTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: ConsoleTheme.violet,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                group.title,
                style: t.ui(
                  size: 12,
                  weight: FontWeight.w800,
                  color: ConsoleTheme.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              CopyButton(text: token, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: ConsoleTheme.codeGround,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: ConsoleTheme.borderFaint),
            ),
            child: Text(
              token,
              style: t.mono(size: 11.5, color: ConsoleTheme.jsonKey, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

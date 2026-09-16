import 'package:flutter/material.dart';

import '../../managers/error_manager.dart';
import '../../models/error_entry.dart';
import '../sheets/error_details_sheet.dart';
import '../theme/console_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/entrance.dart';

/// The Errors tab: captured runtime errors as severity-coded cards.
class ErrorsTab extends StatelessWidget {
  /// The error manager providing entries.
  final ErrorManager manager;

  /// Creates the Errors tab.
  const ErrorsTab({required this.manager, super.key});

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    return StreamBuilder<List<ErrorEntry>>(
      stream: manager.stream,
      initialData: manager.entries,
      builder: (context, snapshot) {
        final entries = snapshot.data ?? const [];
        if (entries.isEmpty) {
          return const EmptyState(
            icon: Icons.check,
            success: true,
            title: 'No errors detected 🎉',
            message:
                'No Flutter, async, or runtime errors have been captured this session.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final entry = entries[i];
            return Padding(
              key: ValueKey(entry.id),
              padding: const EdgeInsets.only(bottom: 11),
              child: EntranceAnimation(
                reduceMotion: t.reduceMotion,
                child: _ErrorCard(entry: entry),
              ),
            );
          },
        );
      },
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.entry});

  final ErrorEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = ConsoleTheme.of(context);
    final color = t.severityColor(entry.severity);
    return GestureDetector(
      onTap: () => showErrorDetailsSheet(context, entry, t),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: ConsoleTheme.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: ConsoleTheme.border),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border(left: BorderSide(color: color, width: 3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: t.tinted(color, bg: 0.13, border: 0.30, radius: 10),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: t.tinted(color, bg: 0.13, border: null, radius: 7),
                          child: Text(
                            entry.severity.label,
                            style: t.ui(size: 11, weight: FontWeight.w800, color: color, letterSpacing: 0.3),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          entry.relativeTime,
                          style: t.mono(size: 11, color: ConsoleTheme.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.title,
                      style: t.ui(size: 14, weight: FontWeight.w700, color: ConsoleTheme.textDim1, height: 1.4),
                    ),
                    if (entry.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.subtitle!,
                        style: t.ui(size: 12, color: ConsoleTheme.textSecondary),
                      ),
                    ],
                    if (entry.stackPreview.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: ConsoleTheme.codeGround,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: ConsoleTheme.borderFaint),
                        ),
                        child: Text(
                          entry.stackPreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.mono(size: 11, color: ConsoleTheme.muted),
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 12, color: ConsoleTheme.mutedDim),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            entry.source ?? 'unknown source',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.mono(size: 11, color: ConsoleTheme.mutedDim),
                          ),
                        ),
                        Text(
                          'View trace ',
                          style: t.ui(size: 11, weight: FontWeight.w700, color: color),
                        ),
                        Icon(Icons.chevron_right, size: 13, color: color),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

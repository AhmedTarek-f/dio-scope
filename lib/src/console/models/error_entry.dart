/// The kind/severity of a captured error, shown in the console Errors tab.
///
/// Each value carries its display [label] (the pill text) and a coarse
/// [severityLabel] used in the detail sheet. Colors live in the console theme.
enum ErrorSeverity {
  /// A widget build/layout/paint error (e.g. `RenderFlex overflowed`).
  widgetError('Widget Error', 'Error'),

  /// An uncaught async error surfaced by the zone/platform dispatcher.
  asyncError('Async Error', 'Warning'),

  /// A failed API call captured by `safeCall`.
  apiError('API Error', 'Error'),

  /// A thrown exception (e.g. null-check on null, cast error).
  exception('Exception', 'Critical');

  /// The pill text, e.g. "Widget Error".
  final String label;

  /// The coarse severity word, e.g. "Critical".
  final String severityLabel;

  const ErrorSeverity(this.label, this.severityLabel);
}

/// A single captured runtime error, shown in the console Errors tab.
class ErrorEntry {
  /// A unique id.
  final String id;

  /// When the error was captured.
  final DateTime timestamp;

  /// The kind/severity.
  final ErrorSeverity severity;

  /// A short one-line title (usually the exception message).
  final String title;

  /// Optional secondary line (e.g. the endpoint or a hint).
  final String? subtitle;

  /// Optional source location, e.g. `data/orders_repo.dart:88`.
  final String? source;

  /// The full stack trace text, if available.
  final String? stackTrace;

  /// Creates an error entry (timestamp defaults to now).
  ErrorEntry({
    required this.id,
    required this.severity,
    required this.title,
    this.subtitle,
    this.source,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// `HH:MM:SS` timestamp.
  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Compact relative age, e.g. `now`, `12s ago`, `4m ago`, `2h ago`.
  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 5) return 'now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// The first non-empty stack line, trimmed to ~60 chars for previews.
  String get stackPreview {
    final trace = stackTrace;
    if (trace == null || trace.isEmpty) return '';
    final line = trace
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    return line.length > 60 ? '${line.substring(0, 60)}…' : line;
  }
}
